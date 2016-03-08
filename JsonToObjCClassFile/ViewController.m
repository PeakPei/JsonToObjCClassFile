//
//  ViewController.m
//  JsonToObjCClassFile
//
//  Created by emerson larry on 16/3/8.
//  Copyright © 2016年 LarryEmerson. All rights reserved.
//
/*
 *本工具用于IOS开发时，以树形结构展开json数据，方便查看具体内容。
 *并且可以一键根据Json数据转成一个或多个数据模型于一体的.h和.m类文件到指定目录中。
 *此工具原作者为吴海超，github地址：https://github.com/netyouli/WHC_DataModelFactory
 *csdn:http://blog.csdn.net/windwhc/article/category/3117381
 *当前版本地址：https://github.com/LarryEmerson/WHC_DataModelFactory
 *当前版本在原版本中添加了Json数据查看面板以及导出数据模型对应的类文件。
 */
#import "ViewController.h"
#import "WHC_XMLParser.h"
#import <objc/runtime.h>

#define kWHC_DEFAULT_CLASS_NAME @("Default")
#define kWHC_CLASS       @("\n@interface %@ :NSObject\n%@\n@end\n")
#define kWHC_PROPERTY    @("@property (nonatomic , strong) %@              * %@;\n")
#define kWHC_CLASS_M     @("@implementation %@\n\n@end\n")


#define kSWHC_CLASS @("\n@objc(%@)\nclass %@ :NSObject{\n%@\n}")
#define kSWHC_PROPERTY @("var %@: %@!;\n")
@interface ViewController ()<NSTextFieldDelegate>{
    NSMutableString       *   _classString;        //存类头文件内容
    NSMutableString       *   _classMString;       //存类源文件内容
}
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (nonatomic , strong)IBOutlet  NSTextField  * classNameField;
@property (nonatomic , strong)IBOutlet  NSTextField  * jsonField;
@property (nonatomic , strong)IBOutlet  NSTextView  * classField;
@property (nonatomic , strong)IBOutlet  NSTextView  * classMField;
@property (nonatomic , strong)IBOutlet  NSButton       * checkBox;
@end

@implementation ViewController{
    NSString *curClassName;
    int cursePosition;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _classString = [NSMutableString new];
    _classMString = [NSMutableString new];
    _classField.editable = NO;
    _classMField.editable = NO;
    _jsonField.drawsBackground = NO;
    _classField.drawsBackground = NO;
    _classMField.drawsBackground = NO;
    // Do any additional setup after loading the view.
    [_jsonField setDelegate:self];
    
}

- (IBAction)clickRadioButtone:(NSButton *)sender{
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
    NSString *str=_jsonField.stringValue;
    str=[str stringByReplacingOccurrencesOfString:@"\\\"" withString: @"\""];
    str=[str stringByReplacingOccurrencesOfString:@"\\\\u" withString: @"\\u"];
    str=[str stringByReplacingOccurrencesOfString:@"\\U" withString: @"\\u"];
    str=[str stringByReplacingOccurrencesOfString:@"=" withString: @":"];
    str=[str stringByReplacingOccurrencesOfString:@"\"{" withString: @"{"];
    str=[str stringByReplacingOccurrencesOfString:@"}\"" withString: @"}"];
    str=[str stringByReplacingOccurrencesOfString:@"\"[" withString: @"["];
    str=[str stringByReplacingOccurrencesOfString:@"]\"" withString: @"]"];
    [_jsonField setStringValue:str];
    NSString *chineseStr=[NSString stringWithCString:[str cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
    cursePosition=0;
    id jsonValue=[self JSONValue:chineseStr];
    chineseStr=@"";
    chineseStr=[self returnFormattedString:jsonValue With:chineseStr];
    [_textView setString:chineseStr];
    return YES;
}
-(NSString *) getPosition{
    NSString *str=@"";
    for (int i=0; i<cursePosition; i++) {
        str=[str stringByAppendingString:@"\t"];
    }
    return str;
}
-(NSString *) addOneLineWith:(NSString *) str To:(NSString *) to{
    return [NSString stringWithFormat:@"%@%@\n",to,str];
}
-(NSString *) returnFormattedString:(id) obj With:(NSString *) thestr{
    NSString *str=thestr;
    if([obj isKindOfClass:[NSDictionary class]]){
        NSDictionary *dic=obj;
        str=[self addOneLineWith:[[self getPosition] stringByAppendingString:@"{"] To:str];
        cursePosition++;
        for (int i=0; i<dic.allKeys.count; i++) {
            NSString *key=[dic.allKeys objectAtIndex:i];
            id tmp=[dic objectForKey:key];
            if([tmp isKindOfClass:[NSDictionary class]]||[tmp isKindOfClass:[NSArray class]]){
                str=[self addOneLineWith:[[self getPosition] stringByAppendingString:[NSString stringWithFormat:@"\"%@\":",key]] To:str];
                str=[self returnFormattedString:tmp With:str];
                if(i<dic.allKeys.count-1){
                    str=[str stringByAppendingString:@",\n"];
                }else{
                    str=[str stringByAppendingString:@"\n"];
                }
            }else{
                id checkType=[dic objectForKey:key];
                BOOL isString=[checkType isKindOfClass:[NSString class]];
                NSString *formatStr=isString?@"\"%@\":\"%@\"":@"\"%@\":%@";
                if(i<dic.allKeys.count-1){
                    formatStr=[formatStr stringByAppendingString:@","];
                }
                str=[self addOneLineWith:[[self getPosition] stringByAppendingString:[NSString stringWithFormat:formatStr,key,checkType]] To:str];
            }
        }
        cursePosition--;
        str=[str stringByAppendingString:[[self getPosition] stringByAppendingString:@"}"]];
    }else if([obj isKindOfClass:[NSArray class]]){
        str=[self addOneLineWith:[[self getPosition] stringByAppendingString:@"["] To:str];
        cursePosition++;
        NSArray *array=obj;
        for (int i=0; i<array.count; i++) {
            id tmp=[array objectAtIndex:i];
            str=[self returnFormattedString:tmp With:str];
            if(i<array.count-1){
                str=[str stringByAppendingString:@",\n"];
            }else{
                str=[str stringByAppendingString:@"\n"];
            }
        }
        cursePosition--;
        str=[str stringByAppendingString:[[self getPosition] stringByAppendingString:@"]"]];
    }
    return str;
}
-(id)JSONValue:(NSString *) str {
    //    NSLogObject(self);
    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;
}
- (IBAction)clickMakeButton:(NSButton*)sender{
    [_classString deleteCharactersInRange:NSMakeRange(0, _classString.length)];
    [_classMString deleteCharactersInRange:NSMakeRange(0, _classMString.length)];
    NSString  * className = _classNameField.stringValue;
    NSString  * json = _jsonField.stringValue;
    if(className == nil){
        className = kWHC_DEFAULT_CLASS_NAME;
    }
    if(className.length == 0){
        className = kWHC_DEFAULT_CLASS_NAME;
    }
    className=[@"DataModel_" stringByAppendingString:className];
    curClassName=[className stringByAppendingString:@"_"];
    
    [_classString appendString:@"#import <UIKit/UIKit.h>\n"];
    [_classMString appendFormat:@"#import \"%@.h\"\n\n",className];
    if(json && json.length){
        NSDictionary  * dict = nil;
        if([json hasPrefix:@"<"]){ //xml
            dict = [WHC_XMLParser dictionaryForXMLString:json];
        }else{ //json
            NSData  * jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
            dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:NULL];
        }
        if(_checkBox.state == 0){
            [_classMString appendFormat:kWHC_CLASS_M,className];
            [_classString appendFormat:kWHC_CLASS,className,[self handleDataEngine:dict key:@""]];
        }else{
            [_classString appendFormat:kSWHC_CLASS,className,className,[self handleDataEngine:dict key:@""]];
        }
        
        
        _classField.string = _classString;
        _classMField.string = _classMString;
        
        
        NSFileManager *file=[NSFileManager defaultManager];
        NSString *path=[NSHomeDirectory( ) stringByAppendingString:@"/DataModels/"];
        [file createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        [file createFileAtPath:[path  stringByAppendingPathComponent:[className stringByAppendingString:@".h"]] contents:[_classString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        [file createFileAtPath:[path  stringByAppendingPathComponent:[className stringByAppendingString:@".m"]] contents:[_classMString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        NSAlert * alert = [NSAlert alertWithMessageText:@"提示" defaultButton:@"确定" alternateButton:nil otherButton:nil informativeTextWithFormat:@"json或者xml数据不能为空"];
        [alert runModal];
#pragma clang diagnostic pop
    }
}

- (NSString*)handleDataEngine:(id)object key:(NSString*)key{
    if(object){
        NSMutableString  * property = [NSMutableString new];
        if([object isKindOfClass:[NSDictionary class]]){
            NSDictionary  * dict = object;
            NSInteger       count = dict.count;
            NSArray       * keyArr = [dict allKeys];
            for (NSInteger i = 0; i < count; i++) {
                id subObject = dict[keyArr[i]];
                if([subObject isKindOfClass:[NSDictionary class]]){
                    NSString * classContent = [self handleDataEngine:subObject key:keyArr[i]];
                    if(_checkBox.state == 0){
                        [property appendFormat:kWHC_PROPERTY,[curClassName stringByAppendingString: keyArr[i]],keyArr[i]];
                        NSString *name=[keyArr[i] stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[keyArr[i] substringToIndex:1] uppercaseString]];
                        [_classString appendFormat:kWHC_CLASS,[curClassName stringByAppendingString: name], classContent];
                        [_classMString appendFormat:kWHC_CLASS_M,[curClassName stringByAppendingString: name]];
                    }else{
                        [property appendFormat:kSWHC_PROPERTY,[curClassName stringByAppendingString: keyArr[i]],keyArr[i]];
                        [_classString appendFormat:kSWHC_CLASS,[curClassName stringByAppendingString: keyArr[i]],keyArr[i],classContent];
                    }
                }else if ([subObject isKindOfClass:[NSArray class]]){
                    NSString * classContent = [self handleDataEngine:subObject key:keyArr[i]];
                    if(_checkBox.state == 0){
                        [property appendFormat:kWHC_PROPERTY,@"NSArray",keyArr[i]];
                        NSString *name=[keyArr[i] stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[keyArr[i] substringToIndex:1] uppercaseString]];
                        [_classString appendFormat:kWHC_CLASS,[curClassName stringByAppendingString: name],classContent];
                        [_classMString appendFormat:kWHC_CLASS_M,[curClassName stringByAppendingString: name]];
                    }else{
                        [property appendFormat:kSWHC_PROPERTY,[curClassName stringByAppendingString: keyArr[i]],@"NSArray"];
                        [_classString appendFormat:kSWHC_CLASS,[curClassName stringByAppendingString: keyArr[i]],keyArr[i],classContent];
                    }
                }else if ([subObject isKindOfClass:[NSString class]]){
                    if(_checkBox.state == 0){
                        [property appendFormat:kWHC_PROPERTY,@"NSString",keyArr[i]];
                    }else{
                        [property appendFormat:kSWHC_PROPERTY,[curClassName stringByAppendingString: keyArr[i]],@"String"];
                    }
                }else if ([subObject isKindOfClass:[NSNumber class]]){
                    if(_checkBox.state == 0){
                        [property appendFormat:kWHC_PROPERTY,@"NSNumber",keyArr[i]];
                    }else{
                        [property appendFormat:kSWHC_PROPERTY,[curClassName stringByAppendingString: keyArr[i]],@"NSNumber"];
                    }
                }else{
                    if(subObject == nil){
                        if(_checkBox.state == 0){
                            [property appendFormat:kWHC_PROPERTY,@"NSString",keyArr[i]];
                        }else{
                            [property appendFormat:kSWHC_PROPERTY,[curClassName stringByAppendingString: keyArr[i]],@"String"];
                        }
                    }else if([subObject isKindOfClass:[NSNull class]]){
                        if(_checkBox.state == 0){
                            [property appendFormat:kWHC_PROPERTY,@"NSString",keyArr[i]];
                        }else{
                            [property appendFormat:kSWHC_PROPERTY,[curClassName stringByAppendingString: keyArr[i]],@"String"];
                        }
                    }
                }
            }
        }else if ([object isKindOfClass:[NSArray class]]){
            NSArray  * dictArr = object;
            NSUInteger  count = dictArr.count;
            if(count){
                NSObject  * tempObject = dictArr[0];
                for (NSInteger i = 0; i < dictArr.count; i++) {
                    NSObject * subObject = dictArr[i];
                    if([subObject isKindOfClass:[NSDictionary class]]){
                        if(((NSDictionary *)subObject).count > ((NSDictionary *)tempObject).count){
                            tempObject = subObject;
                        }
                    }
                    if([subObject isKindOfClass:[NSDictionary class]]){
                        if(((NSArray *)subObject).count > ((NSArray *)tempObject).count){
                            tempObject = subObject;
                        }
                    }
                }
                [property appendString:[self handleDataEngine:tempObject key:key]];
            }
        }else{
            NSLog(@"key = %@",key);
        }
        return property;
    }
    return @"";
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

@end
