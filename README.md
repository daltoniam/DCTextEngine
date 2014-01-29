DCTextEngine
============

An engine that convert text to attributed strings and attributed strings to text. Supports HTML and markdown by default. It is cross platform for iOS and OSX.

# Dependencies #

Requires CoreText.

# Examples #

```objc
NSString *string = @"#Dalton Cherry\n##Dalton Cherry\n*Lorem Ipsum* is simply _dummy_ text of the **printing** and typesetting industry. Lorem Ipsum has been the industry's standard *dummy* text ever since the 1500s. Here is a link to test with [Google](http://www.google.com/), should work fine. Here is a raw link: https://github.com. Hello at @austin, here is that email austin@test.com. youtube video: http://www.youtube.com/watch?v=XibDfYd83Zg here is more text. Some more text";

DCTextEngine *engine = [DCTextEngine engineWithMarkdown];
__weak blockEngine = engine;
[engine addPattern:@"more text." found:^DCTextOptions*(NSString *regex, NSString *text){
    DCTextOptions *opts = [DCTextOptions new];
    NSTextAttachment *attach = [[NSTextAttachment alloc] init];
    attach.image = [UIImage imageNamed:@"subways.png"];
    attach.bounds = CGRectMake(0, 0, self.view.frame.size.width, 100);
    opts.attachment = attach;
    return opts;
}];
[engine addPattern:@"(^|\\s)@\\w+" found:^DCTextOptions*(NSString *regex, NSString *text){
    DCTextOptions *opts = [DCTextOptions new];
    opts.color = [UIColor redColor];
    opts.font = [blockEngine boldFont];
    return opts;
}];
```
![alt tag](https://raw.github.com/daltoniam/DCTextEngine/images/main.png)


# Notes #
As the example shows, the engine has a very powerful parsing via regex, yet still being very simple to create the proper style. This engine will work on iOS 6, but you will be very limited on the style that can be applied. I **strongly** recommend using iOS 7 or above or at least 10.7 or above.

# Contact #

### Dalton Cherry ###
* https://github.com/daltoniam
* http://twitter.com/daltoniam
