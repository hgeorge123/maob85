import boto3
import os
import time
import logging
import datetime

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_ec2_client(current_account_id, event_account_id, region):

    if (current_account_id != event_account_id) : 

        ec2_role = os.environ.get('ROL_EC2','CrossAccountLambdaRole')

        sts_client = boto3.client('sts', region_name = region)
        role_to_assume_arn = 'arn:aws:iam::' + event_account_id + ':role/' + ec2_role
        
        assumed_role_object = sts_client.assume_role(
            RoleArn=role_to_assume_arn,
            RoleSessionName='AssumeRoleSession'
        )

        credentials = assumed_role_object['Credentials']
        ec2_client = boto3.client(
            'ec2',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken'],
            region_name = region
        )    
    else:
        ec2_client = boto3.client('ec2', region_name = region)    
        
    return ec2_client    

def check_dynamodb_for_account(table, event_account_id):

    logger.info(f"Checking whitelist registry for Account ID: {event_account_id}")
    response = table.query(
        Select='SPECIFIC_ATTRIBUTES',
        ProjectionExpression='allow_value, valid_to',
        ReturnConsumedCapacity='NONE',
        KeyConditionExpression=boto3.dynamodb.conditions.Key('allow_type').eq('ACCOUNT_ID') & boto3.dynamodb.conditions.Key('allow_value').eq(event_account_id)
    )

    for item in response.get("Items",[]):
        valid_to = item.get("valid_to")
        if not valid_to:
            return True
        else:
            if datetime.datetime.strptime(valid_to, '%d-%m-%Y') >= datetime.datetime.now():        
                return True
                                
    return False
    
def check_dynamodb_for_ami_global(table, ami_id):

    logger.info(f"Checking whitelist registry for AMI ID: {ami_id}")
    response = table.query(
        Select='SPECIFIC_ATTRIBUTES',
        ProjectionExpression='allow_value, valid_to',
        ReturnConsumedCapacity='NONE',
        KeyConditionExpression=boto3.dynamodb.conditions.Key('allow_type').eq('AMI_ID') & boto3.dynamodb.conditions.Key('allow_value').eq(ami_id)
    )

    for item in response.get("Items",[]):
        valid_to = item.get("valid_to")
        if not valid_to:
            return True
        else:
            if datetime.datetime.strptime(valid_to, '%d-%m-%Y') >= datetime.datetime.now():        
                return True
                
    return False    

def check_dynamodb_for_ami_on_account(table, ami_id, event_account_id):

    logger.info(f"Checking whitelist registry for AMI ID: {ami_id} on ACCOUNT ID: {event_account_id}")
    response = table.query(
        Select='SPECIFIC_ATTRIBUTES',
        ProjectionExpression='allow_value, valid_to',
        ReturnConsumedCapacity='NONE',
        KeyConditionExpression=boto3.dynamodb.conditions.Key('allow_type').eq('AMI_ID_ON_ACCOUNT') & boto3.dynamodb.conditions.Key('allow_value').eq(ami_id),
        FilterExpression=boto3.dynamodb.conditions.Attr('account_id').contains(event_account_id)
    )

    for item in response.get("Items",[]):
        valid_to = item.get("valid_to")
        if not valid_to:
            return True
        else:
            if datetime.datetime.strptime(valid_to, '%d-%m-%Y') >= datetime.datetime.now():        
                return True
                
    return False

def has_allowed_role(instance_profiles, allowed_roles):

    logger.info(f"Checking whitelist registry for Instance Profiles")

    whitelisted_roles = list(set(instance_profiles) & set(allowed_roles))
    logger.info(f"Whitelisted Roles: {whitelisted_roles}")
    return len(whitelisted_roles) > 0      

def has_allowed_tag(instance_details, allowed_tags):
  
  logger.info(f"Checking whitelist registry for Instance Tags")
  instace_tags = instance_details['Reservations'][0]['Instances'][0].get('Tags', [])

  for tag in instace_tags:
      if tag['Key'] in allowed_tags:
          return True
          
  return False
  #whitelisted_tags = list(set(instace_tags) & set(allowed_tags))
  #logger.info(f"Whitelisted Tags: {whitelisted_tags}")
  #return len(whitelisted_tags) > 0      

def lambda_handler(event, context):

    logger.info(f"EventInfo: {event}")
    #instance_ids = [i['instanceId'] for i in event['detail']['responseElements']['instancesSet']['items']]
    event_detail = event.get('detail') or {}
    response_elements = event_detail.get('responseElements') or {}
    instances_sets = response_elements.get('instancesSet') or {}
    items = instances_sets.get('items') or []
    instance_ids = [i['instanceId'] for i in items if 'instanceId' in i]
    instance_profiles = [i['iamInstanceProfile'].get('arn','') for i in items if 'iamInstanceProfile' in i]

    region = event['detail']['awsRegion']

    current_account_id =  context.invoked_function_arn.split(":")[4]    
    event_account_id = event['account']

    dynamodb = boto3.resource('dynamodb')
    tablename = os.environ.get('DYNAMODB_TABLE','ami-control-table-v2')
    table = dynamodb.Table(tablename)

    #Load Common Exception Rules

    # TAG

    response = table.query(
        Select='SPECIFIC_ATTRIBUTES',
        ProjectionExpression='allow_value',
        ReturnConsumedCapacity='NONE',
        KeyConditionExpression=boto3.dynamodb.conditions.Key('allow_type').eq('TAG')
    )    
    
    allowed_tags = [ item.get('allow_value') for item in response.get('Items',{}) ]

    # TAG_ON_ACCOUNT

    response = table.query(
        Select='SPECIFIC_ATTRIBUTES',
        ProjectionExpression='allow_value',
        ReturnConsumedCapacity='NONE',
        KeyConditionExpression=boto3.dynamodb.conditions.Key('allow_type').eq('TAG_ON_ACCOUNT'),
        FilterExpression=boto3.dynamodb.conditions.Attr('account_id').contains(event_account_id),            
    )

    allowed_tags_on_account = [ item.get('allow_value') for item in response.get('Items',{}) ]

    allowed_tags = allowed_tags + allowed_tags_on_account

    logger.info(f"Allowed Tags: {allowed_tags}")
    # PREFIX

    response = table.query(
        Select='SPECIFIC_ATTRIBUTES',
        ProjectionExpression='allow_value',
        ReturnConsumedCapacity='NONE',
        KeyConditionExpression=boto3.dynamodb.conditions.Key('allow_type').eq('PREFIX')
    )    
    
    allowed_prefixes = [ item.get('allow_value') for item in response.get('Items',{}) ]

    logger.info(f"Allowed Prefixes: {allowed_prefixes}")
    
    # ROLE
    
    response = table.query(
        Select='SPECIFIC_ATTRIBUTES',
        ProjectionExpression='allow_value',
        ReturnConsumedCapacity='NONE',
        KeyConditionExpression=boto3.dynamodb.conditions.Key('allow_type').eq('ROLE')
    )    
    
    allowed_roles = [ item.get('allow_value') for item in response.get('Items',{}) ]

    logger.info(f"Allowed Roles: {allowed_roles}")
        
    ec2_client = get_ec2_client(current_account_id, event_account_id, region)
        
    for instance_id in instance_ids:
        instance_details = ec2_client.describe_instances(InstanceIds=[instance_id])
        logger.info(f"Instance Details: {instance_details}")
        ami_id = instance_details['Reservations'][0]['Instances'][0]['ImageId']
        instance_state = instance_details['Reservations'][0]['Instances'][0]['State']['Name']

        valid_ami_id = False
        
        # VALIDATIONS:    
        
        # ACCOUNT_ID VALIDATION
        valid_ami_id = check_dynamodb_for_account(table, event_account_id)

        if (not valid_ami_id):

            #WHITELISTED AMI ID (GLOBAL)  VALIDATION
            valid_ami_id = check_dynamodb_for_ami_global(table, ami_id)

            if (not valid_ami_id):

                #WHITELISTED AMI ID (SPECIFYC ACCOUNT)  VALIDATION
                valid_ami_id = check_dynamodb_for_ami_on_account(table, ami_id, event_account_id)

                if (not valid_ami_id):

                    #WHITELISTED ROLE VALIDATION
                    #valid_ami_id = has_allowed_role(current_account_id, event_account_id, instance_details, allowed_roles, region)
                    valid_ami_id = has_allowed_role(instance_profiles, allowed_roles)
                    
                    if (not valid_ami_id):

                        #WHITELISTED TAG VALIDATION (GLOBAL OR ON ACCOUNT)
                        valid_ami_id = has_allowed_tag(instance_details, allowed_tags)

                        if (not valid_ami_id):

                            #WHITELISTED AMI NAME PREFIX VALIDATION
                            response = ec2_client.describe_images(ImageIds=[ami_id])
                            ami = response['Images'][0]
                            ami_name = ami.get('Name', '')
                            
                            if any(ami_name.startswith(prefix) for prefix in allowed_prefixes):
                                valid_ami_id = True
                                #WHITELISTED AMI NAME PREFIX LOG
                                logger.info(f"Instance ID: {instance_id} with AMI ID: {ami_id} has allowed ami name prefix.")        
                                
                        else:
                            #WHITELISTED TAG LOG
                            logger.info(f"Instance ID: {instance_id} with AMI ID: {ami_id} has allowed tag.")        

                    else:
                        #WHITELISTED ROLE LOG
                        logger.info(f"Instance ID: {instance_id} with AMI ID: {ami_id} has allowed role.")        

                else:
                    #WHITELISTED AMI ID (SPECIFYC ACCOUNT) LOG
                    logger.info(f"Instance ID: {instance_id} has whitelisted AMI ID: {ami_id} on account: {event_account_id}")        

            else:
                #WHITELISTED AMI ID (GLOBAL) LOG
                logger.info(f"Instance ID: {instance_id} has whitelisted AMI ID: {ami_id} (Global)")        

        else:
            # WHITELISTED ACCOUNT_ID LOG
            logger.info(f"Instance ID: {instance_id} with AMI ID: {ami_id} has whitelisted account: {event_account_id}")        

        #FINAL
        if(valid_ami_id):
            #PENDING TO APPROVE THIS CHANGE
            #ec2_client.create_tags(Resources=[instance_id], Tags=[{'Key': 'PENDING TAG', 'Value': 'NEW EC2 INSTANCE WITH APPROVED AMI'}])
            return {
                'compliance_type': 'COMPLIANT',
                'annotation': f'The instance is using an approved AMI: {ami_id}'
            }
        
        else:

            ec2_client.create_tags(Resources=[instance_id], Tags=[{'Key': 'Name', 'Value': 'AMI NO AUTORIZADA'}])

            if instance_state == 'running' or instance_state == 'pending':
                time.sleep(60)  # Wait 60 secs
                ec2_client.stop_instances(InstanceIds=[instance_id])

            ec2_client.terminate_instances(InstanceIds=[instance_id])

            return {
                'compliance_type': 'NON_COMPLIANT',
                'annotation': f'The instance is using an unapproved AMI: {ami_id}. Instance terminated.'
            }
