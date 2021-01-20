import os
import json
import boto3
import botocore
from datetime import date


def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb', region_name = 'us-east-1')
    dynamoTable = "oneconnect-jenkins-dev"

    print(event)

    request = event['Records'][0]['cf']['request']
    headers = request['headers']
    queryString = request['querystring']
    url = request['uri']
    origin = request['origin']

    customer_id = request['headers']['client'][0]['value'] if 'client' in  request['headers'] else ""

    parameters = {
        "customer_id": request['headers']['client'][0]['value'] if 'client' in  request['headers'] else "",
        "fiToken": request['headers']['fiToken'][0]['value'] if 'fiToken' in  request['headers'] else "",
        "appToken": request['headers']['appToken'][0]['value'] if 'appToken' in  request['headers'] else "",            
    }

    processData = Get(dynamodb, dynamoTable, parameters)
    print(processData)

    if processData['Item'] != "NULL":
        request['headers']['host'][0]['value'] = processData['Item']['URL']
        request['origin']['custom']['domainName'] = processData['Item']['URL']
    else:
        print("Unable to retrieve custom URL, processing default")

    print(request)

    return request

def Get(dynamodb, dynamoTable, parameters):

    table = dynamodb.Table(dynamoTable)
    time = date.today().strftime("%d/%m/%Y %H:%M:%S")

    if parameters['customer_id']:
        print("Getting client: {}".format(parameters['customer_id']))
    else:
        result = {
            "HTTPStatusCode": "501",
            "date": time,
            "RequestId": parameters,
            "ResponseMessage": "Not enough parameters {}".format(parameters['customer_id']),
            "Item": "NULL"
        }
        return result

    try:
        response = table.get_item(
           Key={
                'CUSTOMER_ID': parameters['customer_id'],
                'NAME': parameters['customer_id']
            }
        )
        ResponseMessage = "{} has been retrieved succesfully".format(parameters['customer_id'])

        print(response)

        if 'Item' in response:
            result = {
                "HTTPStatusCode": response['ResponseMetadata']['HTTPStatusCode'],
                "date": response['ResponseMetadata']['HTTPHeaders']['date'],
                "RequestId": response['ResponseMetadata']['RequestId'],
                "ResponseMessage": ResponseMessage,
                "Parameters": parameters,
                "Item": response['Item']
            }
        else:
            result = {
                "HTTPStatusCode": response['ResponseMetadata']['HTTPStatusCode'],
                "date": response['ResponseMetadata']['HTTPHeaders']['date'],
                "RequestId": response['ResponseMetadata']['RequestId'],
                "ResponseMessage": ResponseMessage,
                "Parameters": parameters,
                "Item": "NULL"
            }            

        return result

    except botocore.exceptions.ClientError as e:
        print(e)
        result = {
            "HTTPStatusCode": "502",
            "date": time,
            "RequestId": parameters,
            "ResponseMessage": "Unable to retrieve {}".format(parameters['customer_id']),
            "Item": "NULL"
        }
        return result