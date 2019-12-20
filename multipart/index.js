const parse = require('aws-lambda-multipart-parser').parse

exports.handler = async (event) => {
    var event = { ...event, body: parse(event) }
    return {
        statusCode: 200,
        body: JSON.stringify(event)
    }
}

exports.handlerWithSpot = async (event) => {
    var event = { ...event, body: parse(event, true) }
    return {
        statusCode: 200,
        body: JSON.stringify(event)
    }
}