exports.handler = async (event) => {
    return {
        statusCode: 200,
        body: JSON.stringify(event)
    }
}

exports.handlerSimple = async (event) => {
    return event
}