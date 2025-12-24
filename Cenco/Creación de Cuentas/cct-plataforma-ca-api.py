import json
import boto3
import logging  
import urllib3
import ssl
import os
from datetime import datetime 
now = datetime.now() 
date_time = now.strftime("%d/%m/%Y, %I:%M:%S %p")

logger = logging.getLogger()
logger.setLevel(logging.INFO)

#GENERAL SETTINGS
DEBUG = bool(os.environ.get("DEBUG", "1"))

#DYNAMODB SETTINGS
dynamodb = boto3.resource("dynamodb")
accounts_tablename = os.environ.get('DDBAccounts','cct-plataforma-table-registry')
accounts_table = dynamodb.Table(accounts_tablename)
masters_tablename = os.environ.get('DDBMasters','cct-plataforma-table-master')
masters_table = dynamodb.Table(masters_tablename)
masters_table_id = os.environ.get('DDBMastersID','1')

#CencoDesk Integration
api_cencodesk = os.environ.get('APICencoDesk')
api_key_cencodesk = os.environ.get('APIKeyCencoDesk')
cencodesk_specialist = os.environ.get('SpCencoDesk')

#AD API
api_active_directory  = os.environ.get('APIActiveDirectory')

#REQUEST MANAGER FOR OUTGOING API CALLS
# Disable SSL warnings (optional, but recommended when ignoring certificates)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
http = urllib3.PoolManager()

#MASTER DATA GETs
#TODO: ASK IF CAN BE SIMPLIFIED TO ONE FUNCTION THAT RECEIVES TABLE COLUMN
def get_business_units():

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    ddb_items = ddb_data["Item"].get("business_units",[])
    business_units = [{"id":k,"value":v} for k,v in ddb_items.items()]
    if (DEBUG):
        logger.info('Business Units Fetched: {}'.format(business_units))
    return business_units

def get_countries():

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    ddb_items = ddb_data["Item"].get("countries",[])
    countries = [{"id":k,"value":v} for k,v in ddb_items.items()]
    if (DEBUG):
        logger.info('Countries Fetched: {}'.format(countries))
    return countries

def get_accounts_types():

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    ddb_items = ddb_data["Item"].get("accounts_types",[])
    accounts_types = [{"id":k,"value":v} for k,v in ddb_items.items()]
    if (DEBUG):
        logger.info('Accounts Types Fetched: {}'.format(accounts_types))
    return accounts_types

def get_environments():

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    ddb_items = ddb_data["Item"].get("environments",[])
    environments = [{"id":k,"value":v} for k,v in ddb_items.items()]
    if (DEBUG):
        logger.info('Environments Fetched: {}'.format(environments))
    return environments

def get_clouds():

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    ddb_items = ddb_data["Item"].get("clouds",[])
    clouds = [{"id":k,"value":v} for k,v in ddb_items.items()]
    if (DEBUG):
        logger.info('Clouds Fetched: {}'.format(clouds))
    return clouds

def get_groups_and_permissions():

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    groups_and_permissions = ddb_data["Item"].get("groups_and_permissions",{})
    if (DEBUG):
        logger.info('Groups And Permissions Fetched: {}'.format(groups_and_permissions))
    return groups_and_permissions

def get_stacksets():

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    stacksets = ddb_data["Item"].get("stacksets",{})
    if (DEBUG):
        logger.info('StackSets Fetched: {}'.format(stacksets))
    return stacksets

#ACCOUNT DATA (EVENT LOG) GET
def get_account(ID):
    account_types_data = get_accounts_types()
    account_types = {at.get("id"):at.get("value") for at in account_types_data}

    if(ID):
        ddb_data = accounts_table.get_item(Key={'ID': ID})
        account_data = ddb_data.get("Item",{})
        account_data["account_type_name"] = account_types.get(account_data.get("account_type",""),"")
    else:
        #TODO: Some Filtering, Maybe Preprocesing
        account_data_scan = accounts_table.scan()
        account_data = account_data_scan.get("Items",[])

        for account in account_data:
            account["account_type_name"] = account_types.get(account.get("account_type",""),"")

    if (DEBUG):
        logger.info('Account Data Fetched: {}'.format(account_data))
    #TODO: DEFINE REQUIRED DATA OUTPUT
    return account_data

#USERS BY TYPE
def get_users(TYPE):

    ddb_data = masters_table.get_item(Key={'ID': masters_table_id})
    finops_approvers = ddb_data["Item"].get("finops_approvers",[])
    if (DEBUG):
        logger.info('Administration Approvers Fetched: {}'.format(finops_approvers))

    platform_approvers = ddb_data["Item"].get("platform_approvers",[])
    if (DEBUG):
        logger.info('Platform Approvers Fetched: {}'.format(platform_approvers))

    additional_allowed_users = ddb_data["Item"].get("additional_allowed_users",[])
    if (DEBUG):
        logger.info('Additional Allowed Users Fetched: {}'.format(additional_allowed_users))

    match(TYPE):
        case "FINOPS":
            return finops_approvers

        case "PLATFORM":
            return platform_approvers

        case "ADDITIONAL":
            return additional_allowed_users

        case "ALL":
            return list(set(finops_approvers + platform_approvers + additional_allowed_users))

        case _:   
            if (DEBUG):
                logger.info('Warning Unhandled User Type: {}'.format(TYPE))

    return [] 

def query_ad_api(user):

    http_no_ssl = urllib3.PoolManager(
        cert_reqs=ssl.CERT_NONE,
        assert_hostname=False
    )
    
    response = http_no_ssl.request(method='GET', url=api_active_directory + user)
    response = json.loads(response.data)
    if (DEBUG):
        logger.info('ActiveDirectory API Response:  {}'.format(response))

    return response

def query_api_cencodesk(method, path, body):

    #api = api_cencodesk + path
    #response = http.request(method=method, url=api,body = json.dumps(body), headers={"Content-Type": "application/json","X-API-KEY":api_key_cencodesk})
    #if (DEBUG):    
    #    logger.info('CencoDesk API Response:  {}'.format(response.data))

    #return response
    return {}


def update_ddb_accounts_table(ID, action, update_expression, expression_attribute_values):

    updated = accounts_table.update_item(
                    Key={"ID": ID },
                    UpdateExpression=update_expression,
                    ExpressionAttributeValues=expression_attribute_values,
                    ReturnValues="UPDATED_NEW",
                )
    
    if (DEBUG):    
        logger.info('Updated DDB Account Record:  {}'.format(updated))

    query_api_cencodesk('PATCH', "/tickets/" + ID + "/addComment", {"userAd": cencodesk_specialist, "comment": "Request Status Updated: {}".format(action)})    

    if (action in ['REJECT','ACCOUNT_CREATED']):        
        query_api_cencodesk('PATCH', "/tickets/" + ID + "/changeStatus", {"userAd": cencodesk_specialist, "status": "RESOLVED"})    

    return updated

def post_account(data_json):

    response = None
    custom_fields = data_json.get("dataCustomFields",[])
    custom_fields_dict = {}
    
    for cf in custom_fields:
        cf_key = cf.get("label")
        if cf.get("type") == "select_api":
            cf_value = cf.get("value",{}).get("value","")
        else:
            cf_value = cf.get("value","")
        
        custom_fields_dict.update({cf_key: cf_value})
    
    ID = str(data_json.get("ticketNumber",""))
    description = data_json.get("description","")
    business_unit = custom_fields_dict.get("Unidades de Negocio","")
    country = custom_fields_dict.get("Pais","")
    product = custom_fields_dict.get("Producto","")
    environment = custom_fields_dict.get("Ambiente","")
    pep = custom_fields_dict.get("PEP","")
    cloud = custom_fields_dict.get("Cloud","")
    #TODO: SET RIGHT CUSTOM FIELD
    account_type = custom_fields_dict.get("Account Type","")
    owner_ad = custom_fields_dict.get('Owner de Cuenta','')    
    users_ad = query_ad_api(owner_ad)
    valid_owner = users_ad.get("status",False)
    owner_data = users_ad.get("mail",[{}])[0]
    owner_name = owner_data.get("displayName", "") #TODO: Verify Right Field displayName, concatenation of sn and givenName or something else
    owner_account = owner_data.get("sAMAccountName", "") #TODO: Verify Right Field
    
    technical_ad = custom_fields_dict.get('Responsable Tecnico','')
    users_ad = query_ad_api(technical_ad)
    valid_technical = users_ad.get("status",False)
    
    informed_by = data_json.get("informedBy",{}).get("email","")
    users_ad = query_ad_api(informed_by)
    valid_informed_by = users_ad.get("status",False)

    match account_type:
        case "PULSAR" | "PUL" | "DF" | "DIGITAL FACTORY":
            #root_email = "aws.root.{}+{}-{}-{}-{}@cencosud.com".format(country, account_type, business_unit, product, environment).lower()
            #account_name = "Cencosud {} {} {} {} {}".format(country.upper(), account_type.upper(), business_unit.upper(), product.upper(), environment.upper())
            root_email = ("aws.root." + country  + "+" + ("-".join(filter(None, [account_type, business_unit, product, environment])))).lower() + "@cencosud.com"
            account_name = "Cencosud " + (" ".join(filter(None, [country, account_type, business_unit, product, environment]))).upper()

        case "DATA":
            #root_email = "aws.root.{}+{}-{}-{}-{}@cencosud.com".format(country, account_type, business_unit, product, environment).lower()
            #account_name = "Cencosud {} {} {} {} {}".format(country.upper(), account_type.upper(), business_unit.upper(), product.upper(), environment.upper())
            root_email = ("aws.root." + country  + "+" + ("-".join(filter(None, [account_type, environment])))).lower() + "@cencosud.com"
            account_name = "Cencosud " + (" ".join(filter(None, [country, account_type, environment]))).upper()

        case "DATA_BU":
            #root_email = "aws.root.{}+{}-{}-{}-{}@cencosud.com".format(country, account_type, business_unit, product, environment).lower()
            #account_name = "Cencosud {} {} {} {} {}".format(country.upper(), account_type.upper(), business_unit.upper(), product.upper(), environment.upper())
            root_email = ("aws.root." + country  + "+" + ("-".join(filter(None, [account_type, business_unit, environment])))).lower() + "@cencosud.com"                        
            account_name = "Cencosud " + (" ".join(filter(None, [country, account_type, business_unit, environment]))).upper()

        case "SHS":
            root_email = ("aws.root." + country  + "+corp-" + ("-".join(filter(None, [account_type, environment])))).lower() + "@cencosud.com"                        
            account_name = "Cencosud Corp " + (" ".join(filter(None, [account_type, country, environment]))).upper()

        case _: 
            #root_email = "aws.root.{}+{}-{}-{}@cencosud.com".format(country, business_unit, product, environment).lower()
            #account_name = "Cencosud {} {} {} {}".format(country.upper(), business_unit.upper(), product.upper(), environment.upper())
            root_email = ("aws.root." + country  + "+" + ("-".join(filter(None, [business_unit, product, environment])))).lower() + "@cencosud.com"
            account_name = "Cencosud " + (" ".join(filter(None, [country, business_unit, product, environment]))).upper()

    alias = "cenco-" + ("-".join(filter(None, [business_unit,product,account_type,country,environment]))).lower()

    sso_name = "admin"
    sso_lastname = "user"

    #TODO: ASK: assignSpecialist before checking valid businness unit?
    query_api_cencodesk('PATCH', "/tickets/" + ID + "/assignSpecialist", {"userAd": cencodesk_specialist, "specialist": cencodesk_specialist})    

    business_units = {item.get("id"):item.get("value") for item in get_business_units() }

    valid_bu = business_units.get(business_unit)
    ticket_data = get_account(ID)
    exists_ticket = (ID == ticket_data.get("ID"))

    #Validate
    if (not exists_ticket and valid_bu and valid_owner and valid_technical and valid_informed_by):            
    
        created_ticket = accounts_table.put_item(
            Item={
                'ID': ID,
                'account_type': account_type,
                'description': description,
                'account_name': account_name,
                'alias': alias,
                'account_number': "",
                'sso_name': sso_name,
                'sso_lastname': sso_lastname,                        
                'informed_by': informed_by,
                'business_unit': business_unit,
                'country': country,
                'product': product,
                'environment': environment,
                'owner': owner_ad,
                'owner_name': owner_name,
                'owner_account': owner_account,
                'technical': technical_ad,
                'root_email': root_email, 
                'pep': pep,
                'request_status': 'CREATED',
                'agp_number': '',
                'cloud': cloud,
                'events_log': [{'event':'Request Created','timestamp':date_time}]
            })

        if (DEBUG):            
            logger.info('TICKET CREATED: {}'.format(created_ticket))

        response = 'Ticket ' + ID + ' created.'

        query_api_cencodesk('PATCH', "/tickets/" + ID + "/addComment", {"userAd": cencodesk_specialist, "comment": "Ticket Received"})    
        
    else:
        response = 'TICKET REJECTED: {}'.format(ID)
        if not(valid_bu):
            response = "{} - Wrong Business Unit {}".format(response, business_unit)
        if not(valid_owner):
            response = "{} - Invalid Owner {}".format(response, owner_ad)
        if not(valid_technical):
            response = "{} - Invalid Technical {}".format(response, technical_ad)
        if not(valid_informed_by):
            response = "{} - Invalid Informed By {}".format(response, informed_by)
        if (exists_ticket):
            response = "{} - Ticket Already Exists!".format(response)
        if (DEBUG):                    
            logger.info(response)

        query_api_cencodesk('PATCH', "/tickets/" + ID + "/addComment", {"userAd": cencodesk_specialist, "comment": response})    
        query_api_cencodesk('PATCH', "/tickets/" + ID + "/changeStatus", {"userAd": cencodesk_specialist, "status": "RESOLVED"})    
    
    return response

def get_ticket_id_by_name(name):

    response = accounts_table.scan(FilterExpression=boto3.dynamodb.conditions.Attr('account_name').eq(name))

    for item in response.get("Items",[]):
        if item.get("request_status","") != "REJECTED":
            ticket = item      
            break
            
    ID = ticket.get("ID")                

    return ID

def put_account(ID, data_json):

    if (DEBUG):
        logger.info("PUT Account ID: {}".format(ID))                        
        logger.info("PUT Account Data: {}".format(data_json))                        

    response = None
    if (ID == "0" or ID == ""):
        event_type =  data_json.get("detail",{}).get("eventName","")
        event_error_msg = ""
        if (DEBUG):
            logger.info("Event Type: {}".format(event_type))                        

        match event_type:
            case "CreateManagedAccount":
                event_state =  data_json.get("detail",{}).get("serviceEventDetails",{}).get("createManagedAccountStatus",{}).get("state")
                if (DEBUG):
                    logger.info("Event State: {}".format(event_state))                        

                if (event_state == "SUCCEEDED"):
                    action = "ACCOUNT_CREATED"
                else:
                    action = "ACCOUNT_CREATION_FAILED"

            case "ProvisionProduct":
                #TODO: Check
                event_error_code =  data_json.get("detail",{}).get("errorCode")
                if(event_error_code):
                    event_error_msg =  data_json.get("detail",{}).get("errorMessage","")
                action = "ACCOUNT_CREATION_FAILED"

            case _:    
                action = ""
                if (DEBUG):
                    logger.info("Warning Unhandled Event Type: {}".format(event_type))                        

    else:
        action = data_json.get("action","")
        event_error_msg = data_json.get("error_msg","")

        msteams_user = data_json.get("msteams_user","")
        msteams_team = data_json.get("msteams_team","")
        msteams_note = data_json.get("msteams_note","")
        account_data = get_account(ID)

    if (DEBUG):
        logger.info("Action: {}".format(action))                        

    match (action):
        case "REJECT":
            finops_approvers = get_users("FINOPS")
            platform_approvers = get_users("PLATFORM")
            approvers = list(set(finops_approvers + platform_approvers))
            if (not msteams_user in approvers):
                event_text = "Forbidden: User ({}) is not a valid FinOps nor Platform Approver".format(msteams_user)
                event = [{'timestamp':date_time, 'event':event_text, 'user':msteams_user, 'note':msteams_note}]
                update_expression = "SET events_log = list_append(events_log, :event)"
                expression_attribute_values = {":event": event}
            else:
                new_status = "REJECTED"
                event_text = "Request Rejected By {} Team".format(msteams_team)
                event = [{'timestamp':date_time, 'event':event_text, 'user':msteams_user, 'note':msteams_note}]
                update_expression = "SET request_status = :status, events_log = list_append(events_log, :event)"
                expression_attribute_values = {":status":new_status, ":event": event}

            update_ddb_accounts_table(ID, action, update_expression, expression_attribute_values)
            response = event_text

        case "DUPLICATED_ROOT_EMAIL":
            existing_account = event_error_msg
            new_status = "REJECTED"
            if (existing_account):
                event_text = "Request Rejected: Provided Root Email Already Exists on Account: {}".format(existing_account)
                event = [{'timestamp':date_time, 'event':event_text}]
                update_expression = "SET request_status = :status, account = :account, events_log = list_append(events_log, :event)"
                expression_attribute_values = {":status":new_status, ":event": event, ":account": existing_account}
            else:
                event_text = "Request Rejected: Provided Root Email Already Exists"
                event = [{'timestamp':date_time, 'event':event_text}]
                update_expression = "SET request_status = :status, events_log = list_append(events_log, :event)"
                expression_attribute_values = {":status":new_status, ":event": event}

            update_ddb_accounts_table(ID, action, update_expression, expression_attribute_values)
            response = event_text

        case "FINOPS_APPROVED":
            account_status = account_data.get('request_status')
            if (account_status in ['CREATED','PLATFORM_APPROVED']):
                finops_approvers = get_users("FINOPS")
                if (not msteams_user in finops_approvers):
                    event_text = "Forbidden: User ({}) is not a valid FinOps Approver".format(msteams_user)
                    event = [{'timestamp':date_time, 'event':event_text, 'user':msteams_user, 'note':msteams_note}]
                    update_expression = "SET events_log = list_append(events_log, :event)"
                    expression_attribute_values = {":event": event}
                else:
                    if(account_status =="PLATFORM_APPROVED"):
                        new_status = "APPROVED"
                        event_text = "Request Approved by FinOps Team. Approval Process Completed"
                    else:
                        new_status = "FINOPS_APPROVED"
                        event_text = "Request Approved by FinOps Team"

                    event = [{'timestamp':date_time, 'event':event_text, 'user':msteams_user, 'note':msteams_note}]
                    update_expression = "SET request_status = :status, events_log = list_append(events_log, :event)"
                    expression_attribute_values = {":status":new_status, ":event": event}


                update_ddb_accounts_table(ID, action, update_expression, expression_attribute_values)
                response = event_text

        case "PLATFORM_APPROVED":
            account_status = account_data.get('request_status')
            if (account_status in ['CREATED','FINOPS_APPROVED']):
                platform_approvers = get_users("PLATFORM")
                if (not msteams_user in platform_approvers):
                    event_text = "Forbidden: User ({}) is not a valid Platform Approver".format(msteams_user)
                    event = [{'timestamp':date_time, 'event':event_text, 'user':msteams_user, 'note':msteams_note}]
                    update_expression = "SET events_log = list_append(events_log, :event)"
                    expression_attribute_values = {":event": event}
                else:

                    if(account_status =="FINOPS_APPROVED"):
                        new_status = "APPROVED"
                        event_text = "Request Approved by Platform Team. Approval Process Completed"
                    else:
                        new_status = "PLATFORM_APPROVED"
                        event_text = "Request Approved by Platform Team"

                    event = [{'timestamp':date_time, 'event':event_text, 'user':msteams_user, 'note':msteams_note}]
                    update_expression = "SET request_status = :status , events_log = list_append(events_log, :event)"
                    expression_attribute_values = {":status":new_status, ":event": event}

                update_ddb_accounts_table(ID, action, update_expression, expression_attribute_values)
                response = event_text

        case "ACCOUNT_CREATED":
            #TODO: Find additional account data to log
            account_number = data_json.get("detail",{}).get("serviceEventDetails",{}).get("createManagedAccountStatus",{}).get("account",{}).get("accountId")
            account_name = data_json.get("detail",{}).get("serviceEventDetails",{}).get("createManagedAccountStatus",{}).get("account",{}).get("accountName")
            if (DEBUG):
                logger.info("Created Account: {} ({})".format(account_name, account_number))                        

            ID = get_ticket_id_by_name(account_name)
            if (ID):
                new_status = "ACCOUNT_CREATED"
                event_text = "Account {} Created Successfully".format(account_number)
                event = [{'event':event_text,'timestamp':date_time}]
                update_expression = "SET request_status = :status, account_number = :account_number , events_log = list_append(events_log, :event)"
                expression_attribute_values = {":status":new_status, ":account_number": account_number, ":event": event}
                update_ddb_accounts_table(ID, action, update_expression, expression_attribute_values)
                response = event_text
            else:
                if (DEBUG):
                    logger.info("Missing ID to Update DynamoDB Table")

        case "ACCOUNT_CREATION_FAILED":
            if (not ID):
                account_name = data_json.get("detail",{}).get("requestParameters",{}).get("provisionedProductName")
                if (DEBUG):
                    logger.info("Failed to Create Account: {}".format(account_name))                        
            
                ID = get_ticket_id_by_name(account_name)

            if (ID):
                new_status = "ACCOUNT_CREATION_FAILED"
                event_text = "Account Creation Failed: {}".format(event_error_msg)
                event = [{'event':event_text,'timestamp':date_time}]
                update_expression = "SET request_status = :status, events_log = list_append(events_log, :event)"
                expression_attribute_values = {":status":new_status, ":event": event}
                update_ddb_accounts_table(ID, action, update_expression, expression_attribute_values)
                response = event_text
            else:
                if (DEBUG):
                    logger.info("Missing ID to Update DynamoDB Table")

        case "CHECKING_STACKSETS" | "STACKSETS_OK" | "STACKSETS_FAIL" | "SETTING_UP_GROUPS_AND_PERMISSIONS" | "GROUPS_AND_PERMISSIONS_FAIL" | "GROUPS_AND_PERMISSIONS_OK" | "CREATING_ALIAS" | "CREATE_ALIAS_OK" | "CREATE_ALIAS_FAIL" |"FINISHED":

            new_status = action
            event_text = "{} - {}".format(new_status, event_error_msg)
            event = [{'timestamp':date_time, 'event':event_text}]
            update_expression = "SET request_status = :status, events_log = list_append(events_log, :event)"
            expression_attribute_values = {":status":new_status, ":event": event}
            update_ddb_accounts_table(ID, action, update_expression, expression_attribute_values)
            response = event_text

        case _:
            response = 'WARNING: Unhandled action {} for http method: PUT'.format(action)
            if (DEBUG):
                logger.info(response)                        

    return response

#MAIN FUNCTION
def lambda_handler(event, context):

    if (DEBUG):
        logger.info('Event: {}'.format(event))
        logger.info('Context: {}'.format(context))

    try:
        response = None
        http_method = event.get('method') or event.get('context',{}).get('http-method')
        request_path = event.get('resource_path') or event.get('context',{}).get('resource_path')
        if (DEBUG):
            logger.info('http_method: {}'.format(http_method))

        match (http_method):
            case "GET":
                match(request_path):
                    case "/business_units":
                        response = get_business_units()

                    case "/countries":
                        response = get_countries()

                    case "/accounts_types":
                        response = get_accounts_types()

                    case "/environments":
                        response = get_environments()

                    case "/clouds":
                        response = get_clouds()

                    case "/groups_and_permissions":
                        response = get_groups_and_permissions()

                    case "/stacksets":
                        response = get_stacksets()

                    case "/account/{ID}" | "/account":
                        ID = event.get('params',{}).get('path',{}).get('ID')
                        response = get_account(ID)

                    case "/users/{TYPE}":
                        TYPE = event.get('params',{}).get('path',{}).get('TYPE')
                        response = get_users(TYPE)

                    case _:
                        response = 'WARNING: Unhandled path {} for http method: {}'.format(request_path, http_method)
                        if (DEBUG):
                            logger.info(response)                        

            case "POST":
                match(request_path):
                    #CREATE ACCOUNT REQUEST
                    case "/account":

                        request_json = event['body-json']
                        data_json = request_json.get("data",{})
                        response = post_account(data_json)

                    case _:
                        response = 'WARNING: Unhandled path {} for http method: {}'.format(request_path, http_method)
                        if (DEBUG):
                            logger.info(response)                        

            case "PUT":
                match(request_path):
                    #UPDATE ACCOUNT REQUEST
                    case "/account/{ID}" | "/account_lambda/{ID}":

                        ID = event.get('params',{}).get('path',{}).get('ID') or ""
                        request_json = event['body-json']
                        response = put_account(ID, request_json)

                    case _:
                        response = 'WARNING: Unhandled path {} for http method: {}'.format(request_path, http_method)
                        if (DEBUG):
                            logger.info(response)                        

            case _:
                response = 'WARNING: Unhandled http method: {}'.format(http_method)
                if (DEBUG):
                    logger.info(response)

    except  Exception as e:
        if (DEBUG):       
            logger.info('ERROR: {}'.format(str(e)))
        response = 'Error: ' + str(e)
        
    return response