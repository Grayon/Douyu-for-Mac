debugMessages.decryptedCodes.push({workflow});
var patchCode = function(workflow) {
    var testVari = /(\w+)=(\w+)\([\w\+]+\);.*?(\w+)="\w+";/.exec(workflow);
    if (testVari && testVari[1] == testVari[2]) {
        {workflow} += testVari[1] + "[" + testVari[3] + "] = function() {return true;};";
    }
};
patchCode({workflow});
var subWorkflow = /(?:\w+=)?eval\((\w+)\)/.exec({workflow});
if (subWorkflow) {
    var subPatch = (
                    "debugMessages.decryptedCodes.push('sub workflow: ' + subWorkflow);" +
                    "patchCode(subWorkflow);"
                    ).replace(/subWorkflow/g, subWorkflow[1]) + subWorkflow[0];
    {workflow} = {workflow}.replace(subWorkflow[0], subPatch);
}
eval({workflow});
