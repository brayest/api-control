import os
import json
import boto3

def lambda_handler(event, context):

    dynamodb = boto3.resource('dynamodb')

    dynamoTable = os.environ['DYNAMO_TABLE']

    try:
        queryStringParameters = event['queryStringParameters']

        parameters = {
            "customer_id": queryStringParameters['customer_id'] if 'customer_id' in queryStringParameters else "",
            "name": queryStringParameters['name'] if 'name' in queryStringParameters else "",
            "url": queryStringParameters['url'] if 'url' in queryStringParameters else "",
            "fiToken": queryStringParameters['fiToken'] if 'fiToken' in queryStringParameters else "",
            "appToken": queryStringParameters['appToken'] if 'appToken' in queryStringParameters else ""            
        }

        if event['requestContext']['http']['path'] == '/put':
            processData = Put(dynamodb, dynamoTable, parameters)

        return processData
    except Exception as e:
        print(e)
        return str(e)

def Put(dynamodb, dynamoTable, parameters):

    table = dynamodb.Table(dynamoTable)

    if parameters['customer_id'] and parameters['name'] and parameters['url']:
        print("Adding new client: {}".format(parameters['name']))
    else:
        return "customer_id, name and url are required values"

    try:
        response = table.put_item(
           Item={
                'CUSTOMER_ID': parameters['customer_id'],
                'NAME': parameters['name'],
                'URL': parameters['url'],
                "FI_TOKEN": parameters['fiToken'],
                "APP_TOKEN": parameters['appToken']
            }
        )
        ResponseMessage = "{} has been added succesfully".format(parameters['name'])

        print(response)

        result = {
            "HTTPStatusCode": response['ResponseMetadata']['HTTPStatusCode'],
            "date": response['ResponseMetadata']['HTTPHeaders']['date'],
            "RequestId": response['ResponseMetadata']['RequestId'],
            "ResponseMessage": ResponseMessage
        }

        return result

    except Exception as e:
        print(e)
        return e

def Get(dynamodb, dynamoTable, parameters):

    table = dynamodb.Table(dynamoTable)

    if parameters['customer_id'] and parameters['name'] and parameters['url']:
        print("Adding new client: {}".format(parameters['name']))
    else:
        return "customer_id, name and url are required values"

    try:
        response = table.get_item(
           Item={
                'CUSTOMER_ID': parameters['customer_id'],
                'NAME': parameters['name'],
                "FI_TOKEN": parameters['fiToken'],
                "APP_TOKEN": parameters['appToken']
            }
        )
        ResponseMessage = "{} has been retrieved succesfully".format(parameters['name'])

        print(response)

        result = {
            "HTTPStatusCode": response['ResponseMetadata']['HTTPStatusCode'],
            "date": response['ResponseMetadata']['HTTPHeaders']['date'],
            "RequestId": response['ResponseMetadata']['RequestId'],
            "ResponseMessage": ResponseMessage,
            "Item": response['Item']
        }

        return result

    except Exception as e:
        print(e)
        return e