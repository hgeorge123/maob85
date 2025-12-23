import json
import boto3
import logging    
import urllib3
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

#GENERAL SETTINGS
DEBUG = bool(os.environ.get("DEBUG", "1"))

FINOPS_MSTEAMS_WEBHOOK = os.environ.get("FINOPS_MSTEAMS_WEBHOOK", "https://your-teams-webhook-url")
PLATFORM_MSTEAMS_WEBHOOK = os.environ.get("PLATFORM_MSTEAMS_WEBHOOK", "https://your-teams-webhook-url")

#DYNAMODB SETTINGS
dynamodb = boto3.resource("dynamodb")
masters_tablename = os.environ.get('DDBMasters','table-master')
masters_table = dynamodb.Table(masters_tablename)
masters_table_id = os.environ.get('DDBMastersID','1')

#REQUEST MANAGER FOR OUTGOING API CALLS
http = urllib3.PoolManager()

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

def send_teams_notification(team, json_data):

    ID = json_data.get("ID",{}).get("S","") 
    if team == "F":
        action = "FINOPS_APPROVED"
    else:
        action = "PLATFORM_APPROVED"

    business_units = get_business_units()
    bu = json_data.get('business_unit',{}).get("S","") 
    business_unit = business_units.get(bu,'')

    countries = get_countries()
    co = json_data.get('country',{}).get("S","") 
    country = countries.get(co,'') 

    accounts_types = get_accounts_types()
    at = json_data.get('account_type',{}).get("S","") 
    account_type = accounts_types.get(at,'') 

    environments = get_environments()
    en = json_data.get('environment',{}).get("S","") 
    environment = environments.get(en,'')

    clouds = get_clouds()
    cl = json_data.get('cloud',{}).get("S","") 
    cloud = clouds.get(cl,'')

    if (DEBUG):
        logger.info('Send MS Teams Notification')

    if (team =="F"):
        url = FINOPS_MSTEAMS_WEBHOOK
    else:
        url = PLATFORM_MSTEAMS_WEBHOOK

    headers = {
        'Content-Type': 'application/json'
    }
    payload = {
    "type": "AdaptiveCard",
    "version": "1.5",
    "body": [
        {
            "type": "TextBlock",
            "text": "New Approval Request for Account Creation",
            "size": "large",
            "weight": "bolder",
            "color": "accent"
        },
        {
            "type": "TextBlock",
            "text": "**Request ID:** " + ID + " for Account Creation",
            "wrap": True,
            "spacing": "medium"
        },
        {
            "type": "TextBlock",
            "text": "**Cloud:** " + cloud,
            "wrap": True,
            "spacing": "medium"
        },
        {
            "type": "TextBlock",
            "text": "**Account Type:** " + account_type,
            "wrap": True,
            "spacing": "medium"
        },
        {
            "type": "TextBlock",
            "text": "**Account Name:** " + json_data.get('account_name',{}).get("S",""),
            "wrap": True,
            "spacing": "medium"
        },
        {
            "type": "TextBlock",
            "text": "**Description:** " + json_data.get('description',{}).get("S",""),
            "wrap": True,
            "spacing": "medium"
        },
        {
            "type": "TextBlock",
            "text": "**Root Email:** " + json_data.get('root_email',{}).get("S",""),
            "wrap": True,
            "spacing": "medium"
        },        
        {
            "type": "TextBlock",
            "text": "**Product:** " + json_data.get('product',{}).get("S",""),
            "wrap": True,
            "spacing": "medium"
        },                
        {
            "type": "TextBlock",
            "text": "**Environment:** " + environment,
            "wrap": True,
            "spacing": "medium"
        },          
        {
            "type": "TextBlock",
            "text": "**Country:** " + country,
            "wrap": True,
            "spacing": "medium"
        },              
        {
            "type": "TextBlock",
            "text": "**Business Unit:** " + business_unit,
            "wrap": True,
            "spacing": "medium"
        },                                                      
        {
            "type": "TextBlock",
            "text": "**Informed By:** " + json_data.get('informed_by',{}).get("S",""),
            "wrap": True,
            "spacing": "medium"
        },
        {
            "type": "TextBlock",
            "text": "**Owner:** " + json_data.get('owner',{}).get("S",""),
            "wrap": True,
            "spacing": "medium"
        },    
        {
            "type": "TextBlock",
            "text": "**Technical:** " + json_data.get('technical',{}).get("S",""),
            "wrap": True,
            "spacing": "medium"
        },                  
        {
            "type": "TextBlock",
            "text": "**PEP:** " + json_data.get('pep',{}).get("S",""),
            "wrap": True,
            "spacing": "medium"
        },
        {
            "type": "Input.Text",
            "id": "comments",
            "label": "Enter your comments:",
            "placeholder": "",
            "isMultiline": True,
            "style": "textInput"
        },                          
        {
        "type": "ColumnSet",
        "columns": [
            {
            "type": "Column",
            "width": "stretch",
            "items": [
                {
                "type": "ActionSet",
                "actions": [
                    {
                    "type": "Action.Submit",
                    "title": "Approve",
                    "data": {
                        "team": team,
                        "ID": ID,
                        "approved": True,
                        "action": action
                    },
                    "style": "positive",
                    "id": "submit_ok"
                    }
                ]
                }
            ]
            },
            {
            "type": "Column",
            "width": "stretch",
            "items": [
                {
                "type": "ActionSet",
                "actions": [
                    {
                    "type": "Action.Submit",
                    "title": "Reject",
                    "data": {
                        "team": team,
                        "ID": ID,
                        "approved": False,
                        "action": "REJECT"
                    },
                    "style": "destructive",
                    "id": "submit_deny"
                    }
                ]
                }
            ]
            }
        ],
        "spacing": "medium"
        }
    ],
    "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json"
    }

    response = http.request(method='POST', url=url, body=json.dumps(payload), headers = headers )
    if (DEBUG):            
        logger.info('MS TEAMS (PLATFORM) RESPONSE: {}'.format(response.data))
    
    return response

#MAIN FUNCTION
def lambda_handler(event, context):

    if (DEBUG):
        logger.info('Event: {}'.format(event))
        logger.info('Context: {}'.format(context))

    try:
        response = None
        records = event.get("Records",[])
        for record in records:
            record_body = json.loads(record.get("body"))
            if (DEBUG):
                logger.info('Record: {}'.format(record_body))
            
            event_name = record_body.get("eventName")
            new_ddb_data = record_body.get("dynamodb",{}).get("NewImage",{})
            record_status = new_ddb_data.get("request_status",{}).get("S","") 

            if event_name == "INSERT" and record_status == "CREATED":

                send_teams_notification("F", new_ddb_data)
                send_teams_notification("P", new_ddb_data)
            else: 

                if (DEBUG):
                    logger.info('WARNING: Unhandled event name {} and record status {}'.format(event_name, record_status))

    except  Exception as e:
        if (DEBUG):       
            logger.info('ERROR: {}'.format(e))
        response = 'Error: ' + str(e)
        
    return response