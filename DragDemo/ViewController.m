#import "ViewController.h"

@import JavaScriptCore;
@import UIKit;
@import WebKit;

#import "JSContext+Caching.h"

@interface ViewController ()

@property (strong, nonatomic) UIView *nativeSquareView;
@property (strong, nonatomic) UIView *jscSquareView;
@property (strong, nonatomic) UIView *webkitSquareView;

@property (strong, nonatomic) JSContext *jsContext;
@property (strong, nonatomic) WKWebView *webView;

@property (assign, nonatomic) CGPoint initialTouchLocation;
@property (assign, nonatomic) CGPoint initialSquareLocation;

@end

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  _webView = [[WKWebView alloc] init];
  [_webView evaluateJavaScript:@"\
let initialTouchLocation = null;\
let initialSquareLocation = null;\
function handlePan(gestureState, touchLocation, squareLocation) {\
  if (gestureState === 1) {\
    initialTouchLocation = touchLocation;\
    initialSquareLocation = squareLocation;\
    return initialSquareLocation;\
  } else {\
    let panVector = {\
     x: touchLocation.x - initialTouchLocation.x,\
     y: touchLocation.y - initialTouchLocation.y,\
    };\
    let newSquareLocation = {\
      x: initialSquareLocation.x + panVector.x,\
      y: initialSquareLocation.y + panVector.y,\
    };\
    return newSquareLocation;\
  }\
   }" completionHandler:nil];
  
  _jsContext = [[JSContext alloc] init];
  [_jsContext evaluateScript:@"\
let initialTouchLocation = null;\
let initialSquareLocation = null;\
function handlePan(gestureState, touchLocation, squareLocation) {\
  if (gestureState === 1) {\
    initialTouchLocation = touchLocation;\
    initialSquareLocation = squareLocation;\
    return initialSquareLocation;\
  } else {\
    let panVector = {\
      x: touchLocation.x - initialTouchLocation.x,\
      y: touchLocation.y - initialTouchLocation.y,\
    };\
    let newSquareLocation = {\
      x: initialSquareLocation.x + panVector.x,\
      y: initialSquareLocation.y + panVector.y,\
    };\
    return newSquareLocation;\
  }\
   }" withSourceURL:[NSURL URLWithString:@"file://pan.js"]];
  
  _nativeSquareView = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 90, 90)];
  _nativeSquareView.backgroundColor = UIColor.blueColor;
  [_nativeSquareView addSubview:[self _labelWithText:@"UIKit"]];
  UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(_handlePanNatively:)];
  [_nativeSquareView addGestureRecognizer:panRecognizer];
  [self.view addSubview:_nativeSquareView];
  
  _jscSquareView = [[UIView alloc] initWithFrame:CGRectMake(50, 150, 90, 90)];
  _jscSquareView.backgroundColor = UIColor.greenColor;
  [_jscSquareView addSubview:[self _labelWithText:@"JSC"]];
  UIPanGestureRecognizer *jscPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(_handlePanWithJSC:)];
  [_jscSquareView addGestureRecognizer:jscPanRecognizer];
  [self.view addSubview:_jscSquareView];
  
  _webkitSquareView = [[UIView alloc] initWithFrame:CGRectMake(50, 250, 90, 90)];
  _webkitSquareView.backgroundColor = UIColor.redColor;
  [_webkitSquareView addSubview:[self _labelWithText:@"WebKit"]];
  UIPanGestureRecognizer *webkitPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(_handlePanWithWebKit:)];
  [_webkitSquareView addGestureRecognizer:webkitPanRecognizer];
  [self.view addSubview:_webkitSquareView];
}

- (UILabel *)_labelWithText:(NSString *)text
{
  UILabel *label = [[UILabel alloc] init];
  label.text = text;
  label.textColor = UIColor.whiteColor;
  label.backgroundColor = UIColor.clearColor;
  [label sizeToFit];
  return label;
}

- (void)_handlePanNatively:(UIPanGestureRecognizer *)panRecognizer
{
  [self.view bringSubviewToFront:_nativeSquareView];
  
  if (panRecognizer.state == UIGestureRecognizerStateBegan) {
    _initialTouchLocation = [panRecognizer locationInView:self.view];
    _initialSquareLocation = _nativeSquareView.frame.origin;
  } else {
    CGPoint touchLocation = [panRecognizer locationInView:self.view];
    CGPoint panVector = CGPointMake(touchLocation.x - _initialTouchLocation.x,
                                    touchLocation.y - _initialTouchLocation.y);
    CGPoint newSquareLocation = CGPointMake(_initialSquareLocation.x + panVector.x,
                                            _initialSquareLocation.y + panVector.y);
    _nativeSquareView.frame = (CGRect){.origin = newSquareLocation, .size = _nativeSquareView.frame.size};
  }
}

- (void)_handlePanWithJSC:(UIPanGestureRecognizer *)panRecognizer
{
  [self.view bringSubviewToFront:_jscSquareView];
  
  UIGestureRecognizerState gestureState = panRecognizer.state;
  CGPoint touchLocation = [panRecognizer locationInView:self.view];
  CGPoint squareLocation = _jscSquareView.frame.origin;
  
  JSValue *jsNewSquareLocation = [_jsContext[@"handlePan"] callWithArguments:@[@(gestureState),
                                                                               [JSValue valueWithPoint:touchLocation inContext:_jsContext],
                                                                               [JSValue valueWithPoint:squareLocation inContext:_jsContext]]];
  CGPoint newSquareLocation = [jsNewSquareLocation toPoint];
  _jscSquareView.frame = (CGRect){.origin = newSquareLocation, .size = _jscSquareView.frame.size};
}

- (void)_handlePanWithWebKit:(UIPanGestureRecognizer *)panRecognizer
{
  [self.view bringSubviewToFront:_webkitSquareView];
  
  UIGestureRecognizerState gestureState = panRecognizer.state;
  CGPoint touchLocation = [panRecognizer locationInView:self.view];
  CGPoint squareLocation = _webkitSquareView.frame.origin;
  
  [_webView evaluateJavaScript:[NSString stringWithFormat:@"handlePan(%ld, { x: %f, y: %f }, { x: %f, y: %f })",
                                (long)gestureState,
                                touchLocation.x, touchLocation.y,
                                squareLocation.x, squareLocation.y]
             completionHandler:^(id _Nullable result, NSError * _Nullable error) {
               NSNumber *x = result[@"x"];
               NSNumber *y = result[@"y"];
               CGPoint newSquareLocation = CGPointMake(x.doubleValue, y.doubleValue);
               self ->_webkitSquareView.frame = (CGRect){
                 .origin = newSquareLocation,
                 .size = self->_webkitSquareView.frame.size,
               };
             }];
}
                      
@end
