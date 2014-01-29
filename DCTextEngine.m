////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCTextEngine.m
//
//  Created by Dalton Cherry on 1/14/14.
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCTextEngine.h"
#import <CoreText/CoreText.h>

@interface DCTextPattern : NSObject

//the regular expression you want to match
@property(nonatomic,copy)NSString *regex;

//the options you set for this pattern.
@property(nonatomic,strong)DCTextOptions *options;

//the callback for a pattern
@property(nonatomic,strong)DCTextEngineCallBack callback;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface DCTextEngine ()

@property(nonatomic,strong)NSMutableArray *patterns;

@property(nonatomic,strong)NSDataDetector *detector;

@property(nonatomic,strong)DCTextEngineDetector detectorCallback;

@end

@implementation DCTextEngine

////////////////////////////////////////////////////////////////////////////////////////////////////
-(id)init
{
    if(self = [super init])
    {
        self.patterns = [[NSMutableArray alloc] init];
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSAttributedString*)parse:(NSString*)string
{
    NSMutableAttributedString *mainStr = [[NSMutableAttributedString alloc] initWithString:string];
    if(self.color)
        [mainStr addAttribute:NSForegroundColorAttributeName value:self.color range:NSMakeRange(0, mainStr.length)];
    if(self.font)
        [mainStr addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, mainStr.length)];
    if(self.paragraphStyle)
        [mainStr addAttribute:NSParagraphStyleAttributeName value:self.paragraphStyle range:NSMakeRange(0, mainStr.length)];
    for(DCTextPattern *pattern in self.patterns)
    {
        NSInteger offset = 0;
        NSRange range = NSMakeRange(NSNotFound, NSNotFound);
        do {
            NSString *text = mainStr.string;
            NSInteger end = text.length-offset;
            range = [text rangeOfString:pattern.regex options:NSRegularExpressionSearch range:NSMakeRange(offset, end)];
            //NSLog(@"range is: loc: %d len: %d",range.location,range.length);
            if(range.location != NSNotFound)
                offset = (range.location + range.length);
            else
                break;
            NSString *subText = [text substringWithRange:range];
            //NSLog(@"subtext: %@",subText);
            DCTextOptions *opts = nil;
            if(pattern.callback)
                opts = pattern.callback(pattern.regex,subText);
            else
                opts = pattern.options;
            NSString *replaceText = opts.replaceText;
            if(!replaceText)
                replaceText = subText;
            NSInteger move = replaceText.length - subText.length;
            if(opts.attachment)
                offset = 0;
            else
                offset += move;
            NSAttributedString *replaceStr = [self generateString:opts replace:replaceText];
            [mainStr replaceCharactersInRange:range withAttributedString:replaceStr];
            if(offset > mainStr.length)
                break;
        } while (range.location != NSNotFound);
    }
    if(self.detector)
    {
        BOOL finished = YES;
        do {
            NSString *text = mainStr.string;
            finished = YES;
            NSArray *array = [self.detector matchesInString:text options:kNilOptions range:NSMakeRange(0, mainStr.length)];
            for(NSTextCheckingResult *result in array)
            {
                NSString *subText = [text substringWithRange:result.range];
                DCTextOptions *opts = self.detectorCallback(result,subText);
                NSAttributedString *replaceStr = [self generateString:opts replace:subText];
                [mainStr replaceCharactersInRange:result.range withAttributedString:replaceStr];
                if(replaceStr.length != result.range.length)
                {
                    finished = NO;
                    break;
                }
            }
        } while (!finished);
    }
    return mainStr;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addPattern:(NSString*)regex options:(DCTextOptions*)options
{
    DCTextPattern *pattern = [[DCTextPattern alloc] init];
    pattern.regex = regex;
    pattern.options = options;
    [self.patterns addObject:pattern];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addPattern:(NSString*)regex found:(DCTextEngineCallBack)callback
{
    DCTextPattern *pattern = [[DCTextPattern alloc] init];
    pattern.regex = regex;
    pattern.callback = callback;
    [self.patterns addObject:pattern];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addDetector:(NSTextCheckingType)types found:(DCTextEngineDetector)callback
{
    self.detector = [[NSDataDetector alloc] initWithTypes:types error:nil];
    self.detectorCallback = callback;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSAttributedString*)generateString:(DCTextOptions*)options replace:(NSString*)replaceText
{
    if(options.attachment)
        return [NSAttributedString attributedStringWithAttachment:options.attachment];
    return  [[NSAttributedString alloc] initWithString:replaceText attributes:[self generateAttributes:options]];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSDictionary*)generateAttributes:(DCTextOptions*)options
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if(options.link)
        [dict setObject:options.link forKey:NSLinkAttributeName];
    if(options.font)
        [dict setObject:options.font forKey:NSFontAttributeName];
    else
        [dict setObject:self.font forKey:NSFontAttributeName];
    if(options.color)
        [dict setObject:options.color forKey:NSForegroundColorAttributeName];
    if(options.isUnderline)
        [dict setObject:@1 forKey:NSUnderlineStyleAttributeName];
    if(options.hightlightColor)
        [dict setObject:options.hightlightColor forKey:NSBackgroundColorAttributeName];
    if(options.isStrikeThrough)
    {
        [dict setObject:@1 forKey:NSStrikethroughStyleAttributeName];
        if(options.strikeColor)
            [dict setObject:options.strikeColor forKey:NSStrikethroughColorAttributeName];
    }
    if(options.paragraphStyle)
        [dict setObject:options.paragraphStyle forKey:NSParagraphStyleAttributeName];
#if TARGET_OS_IPHONE
    if(options.textEffect)
        [dict setObject:options.textEffect forKey:NSTextEffectAttributeName];
#endif
    return dict;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(DCFont*)boldFont
{
    return [self processFont:kCTFontBoldTrait];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//-(DCFont*)fontWeight:(CGFloat)weight
//{
//    return [self processFont:kCTFontWeightTrait];
//}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(DCFont*)italicFont
{
    return [self processFont:kCTFontItalicTrait];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(DCFont*)boldAndItalicFont
{
    return [self processFont:kCTFontItalicTrait|kCTFontBoldTrait];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(DCFont*)processFont:(CTFontSymbolicTraits)trait
{
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)self.font.fontName, self.font.pointSize, NULL);
    CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits(font, 0.0, NULL, trait, trait);
    NSString *fontName = (__bridge NSString *)CTFontCopyName(newFont, kCTFontPostScriptNameKey);
    CFRelease(font);
    CFRelease(newFont);
    
    return [DCFont fontWithName:fontName size:self.font.pointSize];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(DCFont*)font
{
    if(!_font)
    {
#if TARGET_OS_IPHONE
        _font = [DCFont preferredFontForTextStyle:UIFontTextStyleBody];
#else
        _font = [DCFont systemFontOfSize:[DCFont systemFontSize]];
#endif
    }
    return _font;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(CGFloat)suggestedHeight:(NSAttributedString*)attributedText width:(CGFloat)width
{
    if(attributedText)
    {
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedText);
        //NSLog(@"frame.size.width: %f",frame.size.width);
        CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,CFRangeMake(0,0),NULL,CGSizeMake(width,10000.0f),NULL);
        //NSLog(@"size: %f",size.height);
        __block CGFloat height = MAX(0.f , ceilf(size.height));
        CFRelease(framesetter);
        //iOS does not calculate the hieght of attachments for some reason
#if TARGET_OS_IPHONE
        [attributedText enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, attributedText.length) options:0
                                usingBlock:^(id value,NSRange range, BOOL *stop){
                                    NSTextAttachment *attach = value;
                                    height += attach.bounds.size.height-10;
                                }];
#endif
        return height;
    }
    return 0;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
//default engines
////////////////////////////////////////////////////////////////////////////////////////////////////
+(DCTextEngine*)engineWithMarkdown
{
    DCTextEngine *engine = [[DCTextEngine alloc] init];
    __weak DCTextEngine *blockEngine = engine;
    [engine addPattern:@"!\\[([^\\[]+)\\]\\(([^\\)]+)\\" found:^DCTextOptions*(NSString *regex, NSString *text){
        NSString *name = nil;
        NSRange nameRange = [text rangeOfString:@"]" options:0 range:NSMakeRange(2, text.length-2)];
        if(nameRange.location > 1)
            name = [text substringWithRange:NSMakeRange(2, nameRange.location-2)];
        NSRange linkRange = [text rangeOfString:@"(" options:0 range:NSMakeRange(0, text.length)];
        NSString *link = [text substringWithRange:NSMakeRange(linkRange.location+1, text.length-(linkRange.location+2))];
        if(nameRange.location > 1)
            name = [text substringWithRange:NSMakeRange(2, nameRange.location-2)];
        DCTextOptions *opts = [DCTextOptions new];
        if(name)
            opts.replaceText = name;
        else
            opts.replaceText = link;
        opts.color = [DCTextEngine linkColor];
        return opts;
    }];
    [engine addPattern:@"\\[([^\\[]+)\\]\\(([^\\)]+)\\" found:^DCTextOptions*(NSString *regex, NSString *text){
        NSString *name = nil;
        NSRange nameRange = [text rangeOfString:@"]" options:0 range:NSMakeRange(1, text.length-1)];
        if(nameRange.location > 1)
            name = [text substringWithRange:NSMakeRange(1, nameRange.location-1)];
        NSRange linkRange = [text rangeOfString:@"(" options:0 range:NSMakeRange(0, text.length)];
        NSString *link = [text substringWithRange:NSMakeRange(linkRange.location+1, text.length-(linkRange.location+2))];
        if(nameRange.location > 1)
            name = [text substringWithRange:NSMakeRange(1, nameRange.location-1)];
        DCTextOptions *opts = [DCTextOptions new];
        if(name)
            opts.replaceText = name;
        else
            opts.replaceText = link;
        opts.color = [DCTextEngine linkColor];
        return opts;
    }];
    [engine addPattern:@"(\\*\\*|__)(\\w+)(.*?)(\\*\\*|__)" found:^DCTextOptions*(NSString *regex, NSString *text){
        DCTextOptions *opts = [DCTextOptions new];
        opts.replaceText = [text stringByReplacingOccurrencesOfString:@"**" withString:@""];
        opts.replaceText = [opts.replaceText stringByReplacingOccurrencesOfString:@"__" withString:@""];
        opts.font = [blockEngine boldFont];
        return opts;
    }];
    [engine addPattern:@"(\\*|_)(\\w+)(.*?)(\\*|_)" found:^DCTextOptions*(NSString *regex, NSString *text){
        DCTextOptions *opts = [DCTextOptions new];
        opts.replaceText = [text stringByReplacingOccurrencesOfString:@"*" withString:@""];
        opts.replaceText = [opts.replaceText stringByReplacingOccurrencesOfString:@"_" withString:@""];
        opts.font = [blockEngine italicFont];
        return opts;
    }];
    [engine addDetector:NSTextCheckingTypeLink found:^DCTextOptions*(NSTextCheckingResult *result, NSString *text){
        DCTextOptions *opts = [DCTextOptions new];
        opts.replaceText = text;
        opts.color = [DCTextEngine linkColor];
        return opts;
    }];
    CGFloat fontSize = [DCTextEngine baseHeadSize];
    CGFloat h1Size = [DCTextEngine baseHeadSize];
    CGFloat h2Size = [DCTextEngine baseHeadSize];
    NSString* tag = @"######";
    for(int i = 0; i < 6; i++)
    {
        [engine addPattern:[NSString stringWithFormat:@"%@.*\n",tag] found:^DCTextOptions*(NSString *regex, NSString *text){
            DCTextOptions *opts = [DCTextOptions new];
            opts.replaceText = [text stringByReplacingOccurrencesOfString:@"#" withString:@""];
            opts.font = [DCFont fontWithName:[blockEngine boldFont].fontName size:fontSize];
            return opts;
        }];
        fontSize += 2;
        if(i == 4)
            h2Size = fontSize;
        else if(i == 5)
            h1Size = fontSize;
        if(tag.length > 1)
            tag = [tag substringFromIndex:1];
    }
    [engine addPattern:@".+\\n=+\\n" found:^DCTextOptions*(NSString *regex, NSString *text){
        DCTextOptions *opts = [DCTextOptions new];
        NSRange range = [text rangeOfString:@"\\n=+" options:NSRegularExpressionSearch];
        opts.replaceText = [text stringByReplacingCharactersInRange:range withString:@""];
        opts.font = [DCFont fontWithName:[blockEngine boldFont].fontName size:h1Size];
        return opts;
    }];
    [engine addPattern:@".+\\n\\-+\\n" found:^DCTextOptions*(NSString *regex, NSString *text){
        DCTextOptions *opts = [DCTextOptions new];
        NSRange range = [text rangeOfString:@"\\n\\-+" options:NSRegularExpressionSearch];
        opts.replaceText = [text stringByReplacingCharactersInRange:range withString:@""];
        opts.font = [DCFont fontWithName:[blockEngine boldFont].fontName size:h2Size];
        return opts;
    }];
    [engine addPattern:@"\\n(\\w*)-+" found:^DCTextOptions*(NSString *regex, NSString *text){
        return [DCTextEngine unorderList:@"-" text:text];
    }];
    [engine addPattern:@"\\n(\\w*)\\++" found:^DCTextOptions*(NSString *regex, NSString *text){
        return [DCTextEngine unorderList:@"+" text:text];
    }];
    [engine addPattern:@"\\n(\\w*)\\*+" found:^DCTextOptions*(NSString *regex, NSString *text){
        return [DCTextEngine unorderList:@"*" text:text];
    }];
    return engine;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(DCTextOptions*)unorderList:(NSString*)replace text:(NSString*)text
{
    DCTextOptions *opts = [DCTextOptions new];
    opts.replaceText = [text stringByReplacingOccurrencesOfString:replace withString:@"  •"];
    return opts;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(DCColor*)linkColor
{
    return [DCColor colorWithRed:52/255.0f green:170/255.0f blue:220/255.0f alpha:1];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(CGFloat)baseHeadSize
{
#if TARGET_OS_IPHONE
    DCFont *temp = [DCFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    return temp.pointSize;
#endif
    return 11;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DCTextOptions

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DCTextPattern

@end
