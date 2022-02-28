__author__ = 'yinshen'
import sys
import os
import commands


class RelayObject:
    api_name = ''
    class_name = ''
    api_prototype = ''
    input_keys = []
    output_keys = []
    needs_cb = False 


    def description(self):
        print '{0}\n' \
              'api_name = {1}\n' \
              'class_name = {2}\n' \
              'api_prototype = {3}\n' \
              'input_keys = {4}\n' \
              'output_keys = {5}\n' \
            .format(
            str(self.__class__),
            self.api_name,
            self.class_name,
            self.api_prototype,
            self.input_keys,
            self.output_keys
        )


        # sample: share(shareTitle,shareUrl,cbId)->(shareSucceed)~ShareController


def func_prototype_2_rO(func_prototype):
    rO = RelayObject()

    l0 = func_prototype.find('_')
    if l0 != -1: return None

    l1 = func_prototype.find('(')
    if l1 == -1: return None
    rO.api_name = func_prototype[0:l1]

    l2 = func_prototype.find(')')
    if l2 == -1: return None
    rO.input_keys = func_prototype[l1 + 1:l2].split(',')
    if len(rO.input_keys) == 1 and rO.input_keys[0] == '':
        rO.input_keys = []

    l3 = func_prototype.rfind('(')
    if l3 == -1: return None

    l4 = func_prototype.rfind(')')
    if l4 == -1: return None

    rO.output_keys = func_prototype[l3 + 1:l4].split(',')

    if len(rO.output_keys) == 1 and rO.output_keys[0] == '':
        rO.output_keys = []
    else:
        rO.input_keys.append('cbId')

    l5 = func_prototype.rfind('~')
    if l5 == -1: return None
    rO.class_name = func_prototype[l5 + 1:].strip('\n')

    rO.api_prototype = func_prototype

    rO.needs_cb = len(rO.output_keys) > 0

    return rO


def marking_func(input_str, api_name):
    func_prefix = 'NativE_' + api_name
    found = input_str.find(func_prefix)
    if found == -1:
        return False
    return True


def oc_template(input_str, rO):
    l = 0
    code = ''
    insert_l = 0
    found = False

    while 1:
        # purpose find sample: @implementation ShareController
        l = input_str[l:].find('@implementation')
        if l == -1: break

        class_l = input_str[l:].find(rO.class_name)

        if class_l == -1: continue

        # found class sample: ShareController
        new_line_l = input_str[l + class_l:].find('\n')

        insert_l = new_line_l + l + class_l

        def compose_func_define(needs_callback):
            ret = ''

            if needs_callback:
                ret = '- (void)NativE_' + rO.api_name + '_context:(id)context'

                for i in range(0, len(rO.input_keys)):
                    type = 'NSString'
                    input_key = rO.input_keys[i]
                    if input_key == '{}': input_key = 'd';type = 'NSDictionary'

                    ret += ' ' + input_key + ':('+type+' *)' + input_key

                ret += '{\n'

                ret += '\t' + rO.api_name + '_CALLBACK_ID = ' + rO.input_keys[-1] + ';'
                return ret
            else:
                ret = '- (void)NativE_' + rO.api_name + '_context:(id)context'

                for i in range(0, len(rO.input_keys)):
                    type = 'NSString'
                    input_key = rO.input_keys[i]
                    if input_key == '{}': input_key = 'd';type = 'NSDictionary'
                    ret += ' ' + input_key + ':('+type+' *)' + input_key
                ret += '{\n' \
                       '\t/* Coding \n\n \t... \n\n\t*/\n' \

                return ret

        def compose_callback_define():
            ret = '- (void)NativE_' + rO.api_name + '_callback:'
            ret2 = ''
            for i in range(0, len(rO.output_keys)):
                type = 'NSString'
                output_key = rO.output_keys[i]
                if output_key == '[]': output_key = 'a';type='NSArray'

                if i == 0:
                    ret += '('+type+' *)' + output_key
                else:
                    ret += ' ' + output_key +':('+type+' *)' + output_key

                ret2 += '\t\t\t\t@\"{0}\":{0},\n'.format(output_key)

            ret += '{\n' \
                   '\t[[NSNotificationCenter defaultCenter]\n' \
                   '\tpostNotificationName:@"NativE_notify"\n' \
                   '\tobject:self\n' \
                   '\tuserInfo:\n' \
                   '\t\t\t@{\n' \
                   '' + ret2 + '' \
                               '\t\t\t\t@\"cbId\":' + rO.api_name + '_CALLBACK_ID\n\t\t\t}];\n' \
                                                                    '}\n'

            return ret

        if rO.needs_cb:
            code = '\n\n#pragma mark -\n' \
                   '#pragma mark Native API - ' + rO.api_name + ' - Function Block\n' \
                                                                'static NSString * ' + rO.api_name + '_CALLBACK_ID = @\"\";\n' \
                                                                                                     '' + compose_func_define(
                True) + '\n' \
                        '\t/* Coding \n\n \t... \n\n\t*/\n' \
                        '}\n\n' \
                        '' + compose_callback_define() + ''

        else:
            code = '\n\n#pragma mark -\n' \
                   '#pragma mark Native API - ' + rO.api_name + ' - Function Block\n' \
                   '' + compose_func_define(False) + '\n' \
                                                     '}\n\n'

        found = True
        break

    if found:
        return input_str[0:insert_l] + code + input_str[insert_l:]
    else:
        return None

def template(file_name, func_prototype):
    rO = func_prototype_2_rO(func_prototype)

    fs = open(file_name, 'r')
    input_str = fs.read()
    fs.close()

    if marking_func(input_str, rO.api_name):
        return None

    new_str = oc_template(input_str, rO)

    fs = open(file_name, 'w')
    fs.write(new_str)
    fs.close()

def scan_each_file(search_path):
    shell_commnad = "find {0} -path '{0}/Build' -prune -o -type f -name '*.m'" .format(search_path)
    (status, output) = commands.getstatusoutput(shell_commnad)
    file_path_list = output.split('\n')

    tag_map = {"push":[]}

    for i in range(0,len(file_path_list)):
        (status, filename) = commands.getstatusoutput("basename {0}" .format(file_path_list[i]))
        if filename != '' and os.path.isdir(file_path_list[i]) == False:
            l1 = filename.rfind('.')
            cer_name = filename[0:l1]
            parse_tag(file_path_list[i],cer_name,tag_map)

    fillCRMap(search_path+'/NativeAPI/NativeAPI/CRMap.h',search_path+'/NativeAPI/NativeAPI/CRMap.m',tag_map['push'])



def parse_tag(file_path,cer_name,tag_map):
    fs = open(file_path,'r')
    code_str = fs.read()
    fs.close()

    push_tag = "//$$push("
    l = code_str.find(push_tag)
    if l != -1:
        l_tmp = code_str[l:].find(")")
        tag_map["push"].append((code_str[l+len(push_tag):l+l_tmp],cer_name))


def fillCRMap(CRMap_h,CRMap_m,push_list):
    fs = open(CRMap_h,'w')

    CRMap_interface = '#import <Foundation/Foundation.h>\n\n' \
                      '@interface CRMap : NSObject\n' \
                      '@end'

    fs.write(CRMap_interface)
    fs.close()

    fs = open(CRMap_m,'w')

    CRMap_implementation = '#import "CRMap.h"\n\n' \
                           '@implementation CRMap\n\n' \

    for (method,cer_name) in push_list:
        CRMap_implementation += '+ (NSString *)CR_'+method+'{ return @"'+cer_name+'"; }\n'

    CRMap_implementation += '@end\n'
    fs.write(CRMap_implementation)
    fs.close()


def scan_api_list(api_list_path, search_path):
    fs = open(api_list_path, 'r')

    while 1:
        line = fs.readline()
        if not line or line == '\n':
            break

        rO = func_prototype_2_rO(line.strip('\n'))
        shell_command = "find {0} \( -name {1}.m -o -name {1}.mm \) -type f".format(search_path, rO.class_name)
        (status, output) = commands.getstatusoutput(shell_command)
        if output != '':
            template(output, rO.api_prototype)

    fs.close()

    scan_each_file(search_path)

# test case
def test_marking_func():
    if marking_func('@interface foo picking @end', 'picking') == True:
        print 'find it'


def test_ro_parse():
    rO = func_prototype_2_rO('share(shareTitle,shareUrl,cbId)->(shareSucceed)~ShareController')
    print rO.description()


def test_annotation():
    template('/Users/yinshen/Desktop/nvshentrunk/nvshen/Tabs/Charge/RewardShareController.m',
               'share(shareTitle,shareUrl)->()~RewardShareController')


if __name__ == '__main__':
    # test_marking_func()
    # test_ro_parse()
    # test_annotation()
    scan_api_list(sys.argv[1], sys.argv[2])
