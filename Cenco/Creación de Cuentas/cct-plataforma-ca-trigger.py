import json
import boto3
import logging
import urllib3
import os

#SCHEDULER
import uuid
from datetime import datetime, timedelta

logger = logging.getLogger()
logger.setLevel(logging.INFO)

#GENERAL SETTINGS
DEBUG = bool(os.environ.get("DEBUG", "1"))

region = os.environ.get('AWS_REGION')
control_tower_account = os.environ.get('ControlTowerAccount')
control_tower_role = os.environ.get('ControlTowerRole')
product_id = os.environ.get('SCProductID')

#DYNAMODB SETTINGS
dynamodb = boto3.resource("dynamodb")
masters_tablename = os.environ.get('DDBMasters','cct-plataforma-table-master')
masters_table = dynamodb.Table(masters_tablename)
masters_table_id = os.environ.get('DDBMastersID','1')
#SECURITY TEAM DYNAMODB TABLE ARN
security_team_ddb_arn = os.environ.get('DDBSecurityTableARN')

#API
API_MASTERS_URL = os.environ.get("API_MASTERS_URL")
API_MASTERS_SECRET_NAME = os.environ.get("API_MASTERS_SECRET_NAME")

#SCHEDULER
WAIT_TIME = int(os.environ.get("WAIT_TIME", "60"))
ALIAS_WAIT_TIME = int(os.environ.get("ALIAS_WAIT_TIME", "15"))
LAMBDA_ARN = os.environ.get("LAMBDA_ARN")
ROLE_ARN = os.environ.get("ROLE_ARN")

#SSO
SSO_INSTANCE_ARN = os.environ.get("SSO_INSTANCE_ARN")

#ALIAS
ALIAS_ROLE_NAME = os.environ.get("ALIAS_ROLE_NAME","cct-plataforma-iam-alias-role") # arn:aws:iam::IDACCOUNT:role/cct-plataforma-iam-alias-role

#REQUEST MANAGER FOR OUTGOING API CALLS
http = urllib3.PoolManager()

#Get Secret from AWS Secret Manager
def get_secret():

    secret_json = {}
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager'
    )

    try:
        secret = client.get_secret_value(SecretId=API_MASTERS_SECRET_NAME)
        secret_json = json.loads(secret["SecretString"])
    except  Exception as e:
        if (DEBUG):       
            logger.info('ERROR: {}'.format(str(e)))

    return secret_json.get(API_MASTERS_SECRET_NAME)

API_MASTERS_APIKEY = get_secret()

sts_client = boto3.client('sts')
role_to_assume_arn = 'arn:aws:iam::' + control_tower_account + ':role/' + control_tower_role

account = sts_client.get_caller_identity().get('Account')

assumed_role_object = sts_client.assume_role(
    RoleArn=role_to_assume_arn,
    RoleSessionName='AssumeRoleSession',
    Tags=[{'Key': 'cct-plataforma','Value': 'aws-account'}]
)

credentials = assumed_role_object['Credentials']
    
orgs_client = boto3.client(
    'organizations',
    aws_access_key_id=credentials['AccessKeyId'],
    aws_secret_access_key=credentials['SecretAccessKey'],
    aws_session_token=credentials['SessionToken']
)    

#Find OU inside Parent
def get_target_ou(parent, name):
    final_ou = None
    paginator = orgs_client.get_paginator('list_organizational_units_for_parent')    
    for page in paginator.paginate(ParentId=parent):
        for ou in page['OrganizationalUnits']:
            if (ou.get("Name","").upper() == name.upper()):
                final_ou = ou.get("Id")
                if (DEBUG):
                    logger.info('Target OU: {}'.format(final_ou))

                return final_ou

    return

#Find OU Worklflow for account
def get_ou(account_type, country, environment, business_unit):

    if (DEBUG):
        logger.info('Get OU for -> Account Type: {} - Country: {} - Environment: {} - Business Unit: {}'.format(account_type, country, environment, business_unit))

    cenco_ou_name = "Cenco"
    #org = orgs_client.describe_organization()
    root = orgs_client.list_roots()['Roots'][0]

    #final_ou = None
    #Cenco OU Id
    cenco_ou = get_target_ou(root['Id'], cenco_ou_name)

    match account_type:
        case "DEFAULT" | "DL":
            if (cenco_ou):
                country_ou = get_target_ou(cenco_ou, country)
                if(country_ou):
                    env_ou = get_target_ou(country_ou, environment)
                    if(env_ou):
                        bu_ou = get_target_ou(env_ou, business_unit)
                        if bu_ou:
                            return bu_ou
                        else:
                            return env_ou
                    else:
                        return country_ou
                else:
                    return cenco_ou
            else:
                return None
            
        #TODO: Define own workflow. Right now Pulsar accounts goes to CCOM OU
        case "PULSAR" | "PUL":
            if (cenco_ou):
                ccom_ou = get_target_ou(cenco_ou, "CCOM")
                if(ccom_ou):
                    env_ou = get_target_ou(ccom_ou, environment)
                    if(env_ou):
                        if country == "CORP":
                            country2 = "SHS"
                        else:
                            country2 = country
                        country_ou = get_target_ou(env_ou, country2)
                        if country_ou:
                            return country_ou
                        else:
                            return env_ou
                    else:
                        return ccom_ou
                else:
                    return cenco_ou
            else:
                return None

        #TODO: Better fix to SHS OU. Right now when "CORP" "country" is received it translates to SHS
        case "DIGITAL FACTORY" | "CCOM" | "DF":
            if (cenco_ou):
                ccom_ou = get_target_ou(cenco_ou, "CCOM")
                if(ccom_ou):
                    env_ou = get_target_ou(ccom_ou, environment)
                    if(env_ou):
                        if country == "CORP":
                            country2 = "SHS"
                        else:
                            country2 = country                        
                        country_ou = get_target_ou(env_ou, country2)
                        if country_ou:
                            return country_ou
                        else:
                            return env_ou
                    
                    else:
                        return ccom_ou
                else:
                    return cenco_ou
            else:
                return None

        #TODO: Ask about DG OU
        case "DATA":
            if (cenco_ou):
                data_ou = get_target_ou(cenco_ou, "Data")
                if(data_ou):
                    country_ou = get_target_ou(data_ou, country)
                    if(country_ou):
                        env_ou = get_target_ou(country_ou, environment)
                        if(env_ou):
                            #return get_target_ou(env_ou, business_unit)
                            return env_ou
                        else:
                            return country_ou
                    else:
                        return data_ou
                else:
                    return cenco_ou
            else:
                return None

        case "DATA_BU":
            if (cenco_ou):
                data_ou = get_target_ou(cenco_ou, "Data")
                if(data_ou):
                    country_ou = get_target_ou(data_ou, country)
                    if(country_ou):
                        env_ou = get_target_ou(country_ou, environment)
                        if(env_ou):
                            bu_ou = get_target_ou(env_ou, business_unit)
                            if bu_ou:
                                return bu_ou
                            else:
                                return env_ou
                        else:
                            return country_ou
                    else:
                        return data_ou
                else:
                    return cenco_ou
            else:
                return None

        case _:
            return None    

# Get Active Provisioning Artifact from Service Catalog
def get_active_provisioning_artifact(product_id):
    try:

        sc_client = boto3.client(
            'servicecatalog',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken'],
            region_name = region
        )

        response = sc_client.describe_product(Id=product_id)
        
        product_artifacts = response['ProvisioningArtifacts']
        if (DEBUG):
            logger.info('Product Artifacts:  {}'.format(product_artifacts))
        
        for pa in product_artifacts:
            response2 = sc_client.describe_provisioning_artifact(ProductId=product_id, ProvisioningArtifactId=pa.get('Id',''))
            if (DEBUG):
                logger.info('Artifact Details:  {}'.format(response2))
            
            artifact = response2['ProvisioningArtifactDetail']
            if artifact.get('Active',False):
                active_artifact = artifact

            if (DEBUG):
                logger.info('Active Artifact Details:  {}'.format(active_artifact))
      
        return active_artifact['Id']
    except Exception as e:

        if (DEBUG):
            logger.info('Error Fetching Artifact:  {}'.format(str(e)))
        return None

# Provision Product (Create Account Request)
def provision_product(product_id, artifact_id, account_name, account_email, sso_first_name, sso_last_name, sso_user_email, ou, id):
    try:

        sc_client = boto3.client(
            'servicecatalog',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken'],
            region_name = region
        )
        
        response = sc_client.provision_product(
            ProductId=product_id,
            ProvisioningArtifactId=artifact_id,
            ProvisionedProductName=account_name.replace(" ","_"),
            ProvisioningParameters=[
                {'Key': 'AccountName', 'Value': account_name},
                {'Key': 'AccountEmail', 'Value': account_email},
                {'Key': 'SSOUserFirstName', 'Value': sso_first_name},
                {'Key': 'SSOUserLastName', 'Value': sso_last_name},
                {'Key': 'SSOUserEmail', 'Value': sso_user_email},
                {'Key': 'ManagedOrganizationalUnit', 'Value': ou}
            ]
        )
        return response
    except Exception as error:
        update_ticket(id, "ACCOUNT_CREATION_FAILED", str(error))
        if (DEBUG):
            logger.info("Error provisioning product: {}".format(str(error)))
        return None

#Update Ticket Status using API
def update_ticket(id, status, msg):
    response = {}
    if (API_MASTERS_URL and API_MASTERS_APIKEY):
        body={
            #"body-json": {
                "action":status,
                "error_msg":msg,
            #}
        }
        response = http.request(method='PUT', url=API_MASTERS_URL + "/account_lambda/" + id, headers={"Content-Type": "application/json","X-API-KEY":API_MASTERS_APIKEY}, body = json.dumps(body))
        response = json.loads(response.data)
        if (DEBUG):
            logger.info('MASTERS API UPDATE ACCOUNT:  {}'.format(response))

    return response

#Get Groups And Permission Sets (by account type) from DynamoDB
def get_groups_and_permissions(account_type):

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    groups_and_permissions = ddb_data["Item"].get("groups_and_permissions",{})
    if (DEBUG):
        logger.info('Groups And Permissions Fetched: {}'.format(groups_and_permissions))
    return groups_and_permissions.get(account_type,{})

#Get Staksets to Validate (by account type) from DynamoDB
def get_stacksets(account_type):

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    stacksets = ddb_data["Item"].get("stacksets",{})
    if (DEBUG):
        logger.info('StackSets Fetched: {}'.format(stacksets))
    return stacksets.get(account_type,{})

#Add Groups and Permission Sets to Account
def add_groups_and_permissions(id, account_type, account_number):
    response = None

    if (SSO_INSTANCE_ARN):

        if (DEBUG):
            logger.info("Setting Up Groups And Permissions to Account {} With Account Type {} (Ticker ID {})".format(account_number, account_type, id))

        groups_and_permissions = get_groups_and_permissions(account_type)
        if (groups_and_permissions):

            update_ticket(id, "SETTING_UP_GROUPS_AND_PERMISSIONS", "")

            sso_admin_client = boto3.client(
                'sso-admin',
                aws_access_key_id=credentials['AccessKeyId'],
                aws_secret_access_key=credentials['SecretAccessKey'],
                aws_session_token=credentials['SessionToken'],
                region_name = region
            )        

            for group, permissions in groups_and_permissions.items():
                for permission in permissions:
                    if (DEBUG):
                        logger.info("Group ({}) And Permissions Set ({}) Assignment".format(group, permission))

                    sso_response = sso_admin_client.create_account_assignment(
                        InstanceArn=SSO_INSTANCE_ARN,
                        TargetId=account_number,
                        TargetType='AWS_ACCOUNT',
                        PermissionSetArn=permission,
                        PrincipalType='GROUP',
                        PrincipalId=group
                    )

                    if (DEBUG):
                        logger.info("SSO Group And Permissions Assignment Response: {} for Group {} and Permmision Set {}".format(sso_response, group, permission))

        else:
            response = 'Warning: No Groups And Permissions Found!'
            update_ticket(id, "GROUPS_AND_PERMISSIONS_FAIL", response)
            if (DEBUG):
                logger.info(response)

    else:
        response = 'Warning: Missing Requiered SSO Instance ARN for Group And Permissions Assignment!'
        update_ticket(id, "GROUPS_AND_PERMISSIONS_FAIL", response)
        if (DEBUG):
            logger.info(response)

    return response

#Verify Groups And Permissions on Account
def verify_groups_and_permissions(id, account_type, account_number):
    response = None

    groups_and_permissions_status = "GROUPS_AND_PERMISSIONS_OK"
    groups_and_permissions_msg = ""
    verify_msgs = []

    if (SSO_INSTANCE_ARN):

        if (DEBUG):
            logger.info("Verifying Groups And Permissions to Account {} With Account Type {} (Ticker ID {})".format(account_number, account_type, id))

        groups_and_permissions = get_groups_and_permissions(account_type)
        if (groups_and_permissions):
            
            sso_admin_client = boto3.client(
                'sso-admin',
                aws_access_key_id=credentials['AccessKeyId'],
                aws_secret_access_key=credentials['SecretAccessKey'],
                aws_session_token=credentials['SessionToken'],
                region_name = region
            )        

            for group, permissions in groups_and_permissions.items():

                try:
                    gps = []
                    paginator = sso_admin_client.get_paginator('list_account_assignments_for_principal')                        

                    for page in paginator.paginate(
                        InstanceArn=SSO_INSTANCE_ARN,
                        PrincipalId=group,
                        PrincipalType='GROUP',
                        Filter={
                            'AccountId': account_number
                        }
                    ):
                        gps.extend(page['AccountAssignments'])
                    
                    p_sets = []
                    for g in gps:
                        p_sets.append(g.get("PermissionSetArn"))
                    
                    if (DEBUG):
                        logger.info("Actual Group {} - Account Permissions Sets {} - Required Permissions Sets: {}".format(group, p_sets, permissions))

                    if (not p_sets or not set(p_sets).issubset(set(permissions))):
                        groups_and_permissions_status = "GROUPS_AND_PERMISSIONS_FAIL"
                        missing_permission_sets = list(set(permissions) - set(p_sets))
                        verify_msgs.append("Group {} Permission Sets Check FAILED. Missing: {}".format(group,missing_permission_sets))

                except Exception as e:
                    groups_and_permissions_status = "GROUPS_AND_PERMISSIONS_FAIL"
                    verify_msgs.append("Group {} Permission Sets Check Failed: {}}".format(group, str(e)))
                    if (DEBUG):
                        logger.info("Error: {}".format(str(e)))
                    continue

            groups_and_permissions_msg =  ", ".join(verify_msgs)
                        
        else:
            groups_and_permissions_msg = "WARNING: No Groups And Permission Sets Defined To Be Verified"
            if (DEBUG):
                logger.info(groups_and_permissions_msg)

    else:
        groups_and_permissions_status = "GROUPS_AND_PERMISSIONS_FAIL"
        groups_and_permissions_msg = 'Warning: Missing Requiered SSO Instance ARN for Group And Permissions Verifying Process!'
        if (DEBUG):
            logger.info(groups_and_permissions_msg)

    update_ticket(id, groups_and_permissions_status, groups_and_permissions_msg)
    return response

#Create an EventBridge Scheduler to a time-based trigger of Stacksets Verification Process
def create_scheduler(id, delay_time, ticket_status):

    if (LAMBDA_ARN):
        if (DEBUG):
            logger.info('CREATE SCHEDULER TO UPDATE TICKET {} TO STATUS :  {}'.format(id, ticket_status))
    
        scheduler_client = boto3.client('scheduler')

        # UNIQUE ID
        unique_id = str(uuid.uuid4())[:8]
        scheduler_name = "ca-schedule-{}-{}".format(id, unique_id)
        
        # SCHEDULE EXPRESSION
        execution_time = datetime.utcnow() + timedelta(minutes=delay_time)
        schedule_expression = f"at({execution_time.strftime('%Y-%m-%dT%H:%M:%S')})"
        
        # LAMBDA PAYLOAD
        payload =   {
                        "method": "PUT",
                        "resource_path": "/account_lambda/{ID}",
                        "params":{
                            "path": {"ID":id}
                        },
                        "body-json": {
                            "action": ticket_status,
                            "error_msg":""
                        }
                    }
        
        try:
            # Crear el scheduler
            response = scheduler_client.create_schedule(
                Name=scheduler_name,
                Description=scheduler_name,
                ScheduleExpression=schedule_expression,
                Target={
                    'Arn': LAMBDA_ARN,
                    'RoleArn': ROLE_ARN,
                    'Input': json.dumps(payload)
                },
                ActionAfterCompletion='DELETE',
                State='ENABLED',
                ScheduleExpressionTimezone='UTC',
                FlexibleTimeWindow={
                    'Mode': 'OFF'
                }
            )
        
        except Exception as e:
            if (DEBUG):
                logger.info("Error: {}".format(str(e)))

    else:
        if (DEBUG):
            logger.info("WARNING: Missing Lambda ARN")

#Stacksets Verification Workflow on Account
def verify_stacksets(id, account_type, account_number):
    response = None

    stacksets_status = "STACKSETS_OK"
    stacksets_msg = ""
    verify_msgs = []

    stacksets_list = get_stacksets(account_type)
    if (stacksets_list):

        if (DEBUG):
            logger.info("Stacksets list: {}".format(stacksets_list))

        cf_client = boto3.client(
            'cloudformation',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken'],
            region_name = region
        )

        for stackset in stacksets_list:
            
            try:
                stackset_instances = []
                instance_paginator = cf_client.get_paginator('list_stack_instances')
                for page in instance_paginator.paginate(
                    StackSetName=stackset,
                    StackInstanceAccount=account_number
                ):
                    stackset_instances.extend(page['Summaries'])
                
                if (not stackset_instances):
                    stacksets_status = "STACKSETS_FAIL"
                    verify_msgs.append("Stackset {} Check FAILED: No Instances Found".format(stackset))
                else:                

                    if (DEBUG):
                        logger.info("Stackset {} instances: {}".format(stackset, stackset_instances))

                    for instance in stackset_instances:
                        instance_region = instance.get('Region')
                        status = instance.get('StackInstanceStatus',{}).get('DetailedStatus')
                        
                        if status != "SUCCEEDED":
                            stacksets_status = "STACKSETS_FAIL"

                        verify_msgs.append("Stackset {} Check On Region {}: {}".format(stackset, instance_region, status))

            except Exception as e:
                stacksets_status = "STACKSETS_FAIL"
                verify_msgs.append("Stackset  {} Check Failed: {}}".format(stackset, str(e)))
                if (DEBUG):
                    logger.info("Error: {}".format(str(e)))
                continue
            
        stacksets_msg =  ", ".join(verify_msgs)

    else:
        if (DEBUG):
            stacksets_msg = "WARNING: No Stacksets Defined To Be Verified"
            logger.info(stacksets_msg)

    update_ticket(id, stacksets_status, stacksets_msg)
    
    return response

# Creates Account Alias
def create_account_alias(id, account_number, alias):
    response = None

    create_alias_status = "CREATE_ALIAS_OK"
    create_alias_msg = ""

    if (DEBUG):
        logger.info("Account Alias Creation Workflow")                    

    try:    
        alias_sts_client = boto3.client('sts')
        role_to_assume_arn = 'arn:aws:iam::' + account_number + ':role/' + ALIAS_ROLE_NAME

        assumed_role_object = alias_sts_client.assume_role(
            RoleArn=role_to_assume_arn,
            RoleSessionName='AssumeRoleSession'
        )

        credentials = assumed_role_object['Credentials']

        iam_client = boto3.client(
            'iam',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )                       

        iam_client.create_account_alias(AccountAlias=alias)

    except Exception as e:
        create_alias_status = "CREATE_ALIAS_FAIL"
        create_alias_msg = str(e)

    update_ticket(id, create_alias_status, create_alias_msg)
    
    return response

# Update Security Team DynamoDB Database
def update_security_team_db(data):

    #TODO: Define dynamodb conection local or remote. Catch
    response = None

    status = "FINISHED"
    msg = "Account creation workflow finished. "

    if (security_team_ddb_arn):

        dynamodb_client = boto3.client('dynamodb')

        if (DEBUG):
            logger.info("Adding Item to Security Team DynamoDB Table")


        id = data.get("ID",{}).get("S","")    
        account_number = data.get("account_number",{}).get("S","")
        business_unit = data.get("business_unit",{}).get("S","")
        country = data.get("country",{}).get("S","")
        product = data.get("product",{}).get("S","")
        account_type = data.get("account_type",{}).get("S","")
        environment = data.get("environment",{}).get("S","")
        alias = data.get("alias",{}).get("S","") #"cenco-{}-{}-{}-{}-{}".format(business_unit,product,account_type,country,environment).lower()
        account_name = data.get("account_name",{}).get("S","")
        owner = data.get("owner_name",{}).get("S","")
        owner_account = data.get("owner_account",{}).get("S","")
        owner_email = data.get("owner",{}).get("S","")
        is_pulsar = "Y" if business_unit in ["PUL","PULSAR"] else "N"

        try:
            item={
                'id_cuenta': {"S": account_number},
                'alias': {"S": alias},
                'ambiente': {"S": environment},
                'name': {"S": account_name},
                'owner': {"S": owner},
                'owner_account': {"S": owner_account},
                'owner_email': {"S": owner_email},                        
                'pulsar': {"S": is_pulsar},
                'security_check': {"S": "N"}, #Fixed?
                'workspaces': {"S": "no"}, #??
            }

            item_data = dynamodb_client.put_item(
                TableName=security_team_ddb_arn, 
                Item=item
            )

            if (item_data):
                msg = "{} Item appended to Security Team DyanamoDB Table".format(msg)    
                if (DEBUG):            
                    logger.info('Item created on secutiry team dynamodb table: {}'.format(item_data))
            else:
                msg = "{} Warning: Cannot append item to Security Team DyanamoDB Table".format(msg)    
        except Exception as e:

            msg = "{} Warning: Cannot append item to Security Team DyanamoDB Table".format(msg, str(e))
            if (DEBUG):       
                logger.info('ERROR: {}'.format(str(e)))
         
    else:
        msg = "{} Warning: Cannot append item to Security Team DyanamoDB Table, missing table ARN".format(msg)


    update_ticket(id, status, msg)
    return response

#Main Lambda Function
def lambda_handler(event, context):
    try:
        response = None    
        id = 0
        logger.info('Event: {}'.format(event))

        pipe_records = event.get("Records",[])

        if (pipe_records):

            #Get Artifact ID
            artifact_id = get_active_provisioning_artifact(product_id)

            for record in pipe_records:
                record_data = json.loads(record.get("body",""))
                if (DEBUG):
                    logger.info("Processing DynamoDB Changed Data: {}".format(record_data))

                id = record_data.get("dynamodb",{}).get("NewImage",{}).get("ID",{}).get("S","")
                request_status = record_data.get("dynamodb",{}).get("NewImage",{}).get("request_status",{}).get("S","")

                match(request_status):
                    case "CREATED":
                        if (DEBUG):
                            logger.info("Verify Root Email Workflow")
                        
                        account_email = record_data.get("dynamodb",{}).get("NewImage",{}).get("root_email",{}).get("S","")

                        if(account_email):
                            existing_account = None

                            paginator = orgs_client.get_paginator('list_accounts')
                            for page in paginator.paginate():
                                for account in page['Accounts']:
                                    if account['Email'].lower() == account_email.lower():
                                        existing_account = account
                                        if (DEBUG):
                                            logger.info("Root Email Exist on Account: {}".format(existing_account))

                                        update_ticket(id, "DUPLICATED_ROOT_EMAIL", existing_account["Id"])
                                        return

                    case "APPROVED":
                        if (DEBUG):
                            logger.info("Account Creation Workflow")

                        if artifact_id:

                            account_name = record_data.get("dynamodb",{}).get("NewImage",{}).get("account_name",{}).get("S","")
                            account_email = record_data.get("dynamodb",{}).get("NewImage",{}).get("root_email",{}).get("S","")
                            sso_first_name = record_data.get("dynamodb",{}).get("NewImage",{}).get("sso_name",{}).get("S","")
                            sso_last_name = record_data.get("dynamodb",{}).get("NewImage",{}).get("sso_lastname",{}).get("S","")
                            sso_user_email = record_data.get("dynamodb",{}).get("NewImage",{}).get("root_email",{}).get("S","")
                            account_type = record_data.get("dynamodb",{}).get("NewImage",{}).get("account_type",{}).get("S","")
                            country = record_data.get("dynamodb",{}).get("NewImage",{}).get("country",{}).get("S","")
                            environment = record_data.get("dynamodb",{}).get("NewImage",{}).get("environment",{}).get("S","")
                            business_unit = record_data.get("dynamodb",{}).get("NewImage",{}).get("business_unit",{}).get("S","")

                            #Get Target OU
                            target_ou = get_ou(account_type, country, environment, business_unit)
                            if (DEBUG):
                                logger.info("Target OU: {}".format(target_ou))

                            if (target_ou):
                                ou_data = orgs_client.describe_organizational_unit(OrganizationalUnitId=target_ou)
                                if (DEBUG):
                                    logger.info("OU Data: {}".format(ou_data))
                            
                                if(ou_data):
                                    managed_organizational_unit = "{} ({})".format(ou_data.get("OrganizationalUnit",{}).get("Name",""),ou_data.get("OrganizationalUnit",{}).get("Id",""))
                            else:
                                error = "Missing Organization Unit."
                                resp = update_ticket(id, "ACCOUNT_CREATION_FAILED", error)
                                if (DEBUG):
                                    logger.info("Account Creation Failed ({}): {}".format(error, resp))

                            #TODO: Ask What to do if there is no Target OU. Right now the account is created as low as it can on the OU tree

                            if (DEBUG):
                                logger.info("ID: {}".format(id))
                                logger.info("Account Name: {}".format(account_name))
                                logger.info("Account Email: {}".format(account_email))
                                logger.info("SSO First Name: {}".format(sso_first_name))
                                logger.info("SSO Last Name: {}".format(sso_first_name))
                                logger.info("SSO Email: {}".format(sso_user_email))
                                logger.info("Organizational Unit: {}".format(managed_organizational_unit))
                            
                            try:
                                result = provision_product(product_id, artifact_id, account_name, account_email, sso_first_name, sso_last_name, sso_user_email, managed_organizational_unit, id)

                                if (DEBUG):
                                    logger.info("Service Catalog Account Creation Request Result: {}".format(result))

                            except  Exception as error:
                                resp = update_ticket(id, "ACCOUNT_CREATION_FAILED", str(error))
                                if (DEBUG):
                                    logger.info("Account Creation Failed ({}): {}".format(str(error), resp))                    

                                pass

                        else:
                            error = "Can't find and active artifact on Service Catalog"
                            resp = update_ticket(id, "ACCOUNT_CREATION_FAILED", error)
                            if (DEBUG):
                                logger.info("Account Creation Failed ({}): {}".format(error, resp))                    

                    #ADD GROUPS AND PERMISSIONS
                    case "ACCOUNT_CREATED":
                        if (DEBUG):
                            logger.info("Account Groups and Permissions Workflow")

                        account_number = record_data.get("dynamodb",{}).get("NewImage",{}).get("account_number",{}).get("S","")
                        account_type = record_data.get("dynamodb",{}).get("NewImage",{}).get("account_type",{}).get("S","DL")
                        #ADD GROUPS AND PERMISSIONS
                        add_groups_and_permissions(id, account_type, account_number)
                        #EVENT BRIDGE SCHEDULE (CREATING_ALIAS)
                        create_scheduler(id, ALIAS_WAIT_TIME, "CREATING_ALIAS")
                        #EVENT BRIDGE SCHEDULE (CHECKING_STACKSETS)
                        create_scheduler(id, WAIT_TIME, "CHECKING_STACKSETS")
                    
                    #CREATING_ALIAS
                    case "CREATING_ALIAS":
                        if (DEBUG):
                            logger.info("Account Stackset Checking Workflow")                    

                        account_number = record_data.get("dynamodb",{}).get("NewImage",{}).get("account_number",{}).get("S","")
                        alias = record_data.get("dynamodb",{}).get("NewImage",{}).get("alias",{}).get("S","")
                        create_account_alias(id, account_number, alias)

                    #VERIFY STACKSETS, GROUPS AND PERMISSIONS
                    case "CHECKING_STACKSETS":
                        if (DEBUG):
                            logger.info("Account Stackset Checking Workflow")                    
                        
                        account_number = record_data.get("dynamodb",{}).get("NewImage",{}).get("account_number",{}).get("S","")                            
                        account_type = record_data.get("dynamodb",{}).get("NewImage",{}).get("account_type",{}).get("S","DL")
                        #VERIFY GROUPS AND PERMISSIONS
                        verify_groups_and_permissions(id, account_type, account_number)
                        #VERIFY STACKSETS
                        verify_stacksets(id, account_type, account_number)
                        #UPDATE SECURITY TEAM DB
                        update_security_team_db(record_data.get("dynamodb",{}).get("NewImage",{}))

                    #DEFAULT
                    case _:
                        if (DEBUG):
                            logger.info("Warning: Unhandled Request Status -> {}".format(request_status))

    except  Exception as error:
        response = 'Error: ' + str(error)
        if (DEBUG):
            logger.info(response)                    
        
    return response