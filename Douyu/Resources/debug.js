var _ub98484234 = ub98484234;
ub98484234 = function(p1, p2, p3) {
    try {
        var result = _ub98484234(p1, p2, p3);
        debugMessages.result = result;
    } catch(e) {
        debugMessages.result = e.message;
    }
    return debugMessages;
};