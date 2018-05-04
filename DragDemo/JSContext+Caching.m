#import "JSContext+Caching.h"

@import ObjectiveC;

@implementation JSContext (Caching)

+ (void)load
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class class = [self class];
    
    SEL originalInit = @selector(init);
    SEL swizzledInit = @selector(ex_init);
    
    Method originalMethod = class_getInstanceMethod(class, originalInit);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledInit);
    
    BOOL didAddMethod = class_addMethod(class, originalInit, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
      class_replaceMethod(class, swizzledInit, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod);
    }
  });
}

- (instancetype)ex_init
{
  static JSVirtualMachine *sharedVM;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    sharedVM = [[JSVirtualMachine alloc] init];
    CFTimeInterval endTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"Allocated shared JSVirtualMachine in %f ms", (endTime - startTime) * 1000);
  });
  
  return [self initWithVirtualMachine:sharedVM];
}

@end
