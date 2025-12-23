import requests

headers = {"Content-Type": "application/json"}

teams_webhook_url = "https://prod-91.westus.logic.azure.com:443/workflows/a9055269e08e457b89a9b4190798aaa6/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=D6e1t9QpxzsfRspz7xKQ7LI7b5-XQ6fm-uTuAIvOMSA"

teams_mesagge = {
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
        "text": "Request ID: 1 for Account Creation",
        "wrap": True,
        "spacing": "medium"
        },
        {
        "type": "TextBlock",
        "text": "Pais: ",
        "wrap": True,
        "spacing": "medium"
        },
        {
        "type": "TextBlock",
        "text": "Ambiente: " ,
        "wrap": True,
        "spacing": "medium"
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
                        "team": "F",
                        "ID": 1,
                        "approved": True,
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
                        "team": "F",
                        "ID": 1,
                        "approved": False,
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

try:
	response = requests.post(teams_webhook_url, headers=headers, json=teams_mesagge)
	response.raise_for_status()
except requests.exceptions.HTTPError as err:
	raise SystemExit(err)

print("Teams alert successfully sent")
	
