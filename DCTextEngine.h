////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCTextEngine.h
//
//  Created by Dalton Cherry on 1/14/14.
////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

#ifndef DCFont
#if TARGET_OS_IPHONE
typedef UIFont DCFont;
#else
typedef NSFont DCFont;
#endif
#endif

#ifndef DCColor
#if TARGET_OS_IPHONE
typedef UIColor DCColor;
#else
typedef NSColor DCColor;
#endif
#endif

///-------------------------------
/// @name Text Options
///-------------------------------

@interface DCTextOptions : NSObject

/**
 Set the font of the text.
 */
@property(nonatomic,strong)DCFont *font;

/**
 Set the text color.
 */
@property(nonatomic,strong)DCColor *color;

/**
 Set the paragraph style.
 */
@property(nonatomic,strong)NSParagraphStyle *paragraphStyle;

/**
 Set the replacement text.
 */
@property(nonatomic,copy)NSString *replaceText;

/**
 Set if the text is underlined.
 */
@property(nonatomic,assign)BOOL isUnderline;

/**
 Set if the text is strikethrough.
 */
@property(nonatomic,assign)BOOL isStrikeThrough;

/**
 Set the strikeThrough color.
 */
@property(nonatomic,strong)DCColor *strikeColor;

/**
 Set a link to go to
 */
@property(nonatomic,copy)NSString *link;

/**
 Set the highlight color.
 */
@property(nonatomic,strong)DCColor *hightlightColor;

/**
 Set a text effect (there is only one right now!)
 */
@property(nonatomic,copy)NSString *textEffect;

/**
 Set a text attachment
 */
@property(nonatomic,strong)id attachment;


@end

///-------------------------------
/// @name Parsing Engine
///-------------------------------

@interface DCTextEngine : NSObject

typedef DCTextOptions* (^DCTextEngineCallBack)(NSString *regex, NSString *text);
typedef DCTextOptions* (^DCTextEngineDetector)(NSTextCheckingResult *result, NSString *text);


/**
 The base font to use for styling. If nil the standard OS font is used.
*/
@property(nonatomic,strong)DCFont *font;

/**
 The base color to use for styling. If nil the standard OS color is used (which is black).
 */
@property(nonatomic,strong)DCColor *color;

/**
 The base paragraph style. If nil the standard paragraph style used.
 */
@property(nonatomic,strong)NSParagraphStyle *paragraphStyle;

/**
 converts the string to the appropriate NSAttributedString.
 @param source string to convert.
 @return new NSAttributedString with proper styling from the source string
*/
-(NSAttributedString*)parse:(NSString*)string;

/**
 Add a regex pattern to find in the string and stylize.
 @param regex is the regular expression to match and style
 @param options is the options you want to add for anything that matches the regex
 */
-(void)addPattern:(NSString*)regex options:(DCTextOptions*)options;

/**
 Add a regex pattern to find in the string and stylize.
 @param regex is the regular expression to match and style
 @param callback is the determine what attributes will be add at parse time.
 */
-(void)addPattern:(NSString*)regex found:(DCTextEngineCallBack)callback;

/**
 Add data detector parsing.
 @param types is the types to run the data detector for
 @param callback is the determine what attributes will be add at parse time.
 */
-(void)addDetector:(NSTextCheckingType)types found:(DCTextEngineDetector)callback;

/**
 @return returns a bold version of the font property.
 */
-(DCFont*)boldFont;

/**
 @return returns a italic version of the font property.
 */
-(DCFont*)italicFont;

/**
 @return returns a italic and bold version of the font property.
 */
-(DCFont*)boldAndItalicFont;

/**
 Find and replace a string with an unordered list string
 @param replace: the string to find and replace.
 @param text: the text that was found.
 @return DCTextOptions with unorder list replace text.
 */
+(DCTextOptions*)unorderList:(NSString*)replace text:(NSString*)text;

/**
 @return returns a suggestedHeight, based on the attributedString.
 */
+(CGFloat)suggestedHeight:(NSAttributedString*)attributedText width:(CGFloat)width;

///-------------------------------
/// @name Default engines
///-------------------------------

/**
 @return returns a new DCTextEngine that supports markdown tags.
 */
+(DCTextEngine*)engineWithMarkdown;

//html engine coming soon!

@end
