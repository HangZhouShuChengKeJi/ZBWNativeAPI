#!/usr/bin/env python
import sys,os

fileApi = open(sys.argv[1], "r")
fileJs = open(sys.argv[2], "r")
apiList = fileApi.readlines()
jsLib = fileJs.readlines()
fileApi.close()
fileJs.close()
startPos = jsLib.index("		//here api start\n")
endPos = jsLib.index("		//here api end\n")
if startPos != -1:
    content = [];
    for line in apiList:
        if len(line.strip()) > 0 and (not line.strip().startswith('//')):
            method = line[:line.find('(')]
            args = line[line.find('(')+1:line.find(')')].split(',')
            rets = line[line.find('->')+3:line.rfind(')')].split(',')
            content.append('		'+method+': function'+str(args).replace('[','(').replace(']','').replace('\'','').replace('{}', 'd')+(', ' if len(args[0]) else '')+'callback) {\n' if len(rets[0]) > 0 else
                           '		'+method+': function'+str(args).replace('[','(').replace(']',')').replace('\'','').replace('{}', 'd')+' {\n')
            content.append('			c(\''+method+'\', {\n')
            if (len(args[0]) > 0):
                for arg in args[:-1]:
                    content.append('				d: d,\n') if arg == '{}' else content.append('				'+arg+': '+arg+',\n')
                content.append('				d: d\n') if args[-1] == '{}' else content.append('				'+args[-1]+': '+args[-1]+'\n')
            else:
                content.append('\n')
            content.append('			}'+((', callback);\n') if  len(rets[0]) > 0 else (');\n')));
            content.append('		},\n\n')
    content = jsLib[:startPos + 2] + content + jsLib[endPos:];
    # print content
    file = open(sys.argv[2], "w")
    file.writelines(content)
    file.close()

fileHtml = open(sys.argv[3], "r")
html = fileHtml.readlines()
fileHtml.close()
startPos = html.index("        <!-- here demo start -->\n")
endPos = html.index("        <!-- here demo end -->\n")
if startPos != -1:
    content = [];
    for line in apiList:
        if len(line.strip()) > 0 and (not line.strip().startswith('//')):
            method = line[:line.find('(')]
            args = line[line.find('(')+1:line.find(')')].split(',')
            rets = line[line.find('->')+3:line.rfind(')')].split(',')

            if len(args) == 1 and args[0] == '': args = []
            if len(rets) == 1 and rets[0] == '': rets = []

            callback_func = ")"
            onclick_func = ""
            hasCallback = "NO"
            if len(rets) >0:
                callback_func = " function(ret){alert(JSON.stringify(ret));})"
                hasCallback = "YES"

            if len(args)>0: onclick_func = "showParamPanel('"+method+"','"+str(args).replace("'","").replace("{}","d")+"','"+hasCallback+"')"
            else: onclick_func = "lx."+method+"("+callback_func
            content.append('        <button class="tableViewCell" id="cell1" onclick="'+onclick_func+'">\n')
            content.append('            <div class="contentLabel">'+method+'</div>\n')
            content.append('       </button>\n')

        #onclick_func = "lx."+method+str(args).replace('[','(').replace(']','').replace('\'\'', '').replace('\'{}\'', 'd')+callback_func

        # content.append('        <button class="tableViewCell" id="cell1" onclick="lx.'+method+str(args).replace('[','(').replace(']','').replace('\'\'', '').replace('\'{}\'', 'd')+(', ' if len(args[0]) else '')+'function(ret){alert(ret);})">\n' if len(rets[0]) > 0 else
        # 	'        <button class="tableViewCell" id="cell1" onclick="lx.'+method+str(args).replace('[','(').replace(']',')').replace('\'\'', '').replace('\'{}\'', 'd')+'">\n')
    content = html[:startPos + 2] + content + html[endPos-1:];
    # print content
    file = open(sys.argv[3], "w")
    file.writelines(content)
    file.close()

# fileHtml = open(sys.argv[3], "r")
# html = fileHtml.readlines()
# fileHtml.close()
# startPos = html.index("         ///here script start\n")
# endPos = html.index("         ///here script end\n")
#
# scripts = []
#
# ident = "\t\t"
#
# scripts.append(ident+"function showParamPanel(method,args,hasCallback){\n")
# scripts.append(ident+"\tvar argsArr = args.replace(\"[\",\"\").replace(\"]\",\"\").split(\",\");\n")
# #scripts.append(ident+"alert(argsArr);\n")
# scripts.append(ident+"\tvar maskPanel = \"<div class='panelbg'></div>")
# scripts.append("<div class='panel'>\";\n")
# scripts.append(ident+"\tfor(var i = 0;i < argsArr.length;i++){ maskPanel+=\"<input class='textfield' placeholder=\"+argsArr[i]+\"></input>\"; }\n")
# scripts.append(ident+"\tmaskPanel+=\"")
# scripts.append("<button class='submit' onclick='dismissParamPanel()' napimethod=\"+method+\" napiargs=\"+args+\" napihascallback=\"+hasCallback+\" >GO</button>")
# scripts.append("</div>\";\n")
# scripts.append(ident+"\t$('.tableView').append(maskPanel);\n")
# scripts.append(ident+"\t$('.panel').css('left',($(document.body).width()-$('.panel').width())/2);\n")
# scripts.append(ident+"}\n")
#
# scripts.append("\n\n")
#
# scripts.append(ident+"function dismissParamPanel(method,args,hasCallback){\n")
# scripts.append(ident+"\tvar method = $('.submit').attr('napimethod');\n")
# scripts.append(ident+"\tvar args = $('.submit').attr('napiargs');\n")
# scripts.append(ident+"\tvar hasCallback = $('.submit').attr('napihascallback');\n")
# scripts.append(ident+"\tvar inputList = $('.panel').find('input')\n")
# scripts.append(ident+"\tfor(var i = 0;i < inputList.length;++i){ if (inputList[i].value != '')  args[i] = inputList[i].value };\n")
# scripts.append(ident+"\tvar func = 'lx.'+method;\n")
# scripts.append(ident+"\talert(func+\"(\"+args.replace('[','(').replace(']',')').replace('\'\'', '').replace('\'{}\'', 'd')+\",function(ret){alert(ret);})\");\n")
# scripts.append(ident+"\t$('.panelbg').remove();\n")
# scripts.append(ident+"\t$('.panel').remove();\n")
# scripts.append(ident+"}\n")
#
# scripts = html[:startPos+2] + scripts + html[endPos-1:];
#
# file = open(sys.argv[3], "w")
# file.writelines(scripts)
# file.close()





