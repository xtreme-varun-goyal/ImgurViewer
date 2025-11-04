//
//  UIView+LiquidGlass.m
//  ImgurViewer
//
//  Created for iOS 15+ modernization - 2025
//  Liquid glass (glassmorphism) effects for modern iOS
//

#import "UIView+LiquidGlass.h"
#import <objc/runtime.h>

static const char kLiquidGlassEffectViewKey;
static const char kLiquidGlassBorderLayerKey;

@implementation UIView (LiquidGlass)

- (void)applyLiquidGlassEffect:(LiquidGlassStyle)style cornerRadius:(CGFloat)cornerRadius {
    [self applyLiquidGlassEffect:style cornerRadius:cornerRadius tintColor:nil alpha:0.85];
}

- (void)applyLiquidGlassEffect:(LiquidGlassStyle)style
                  cornerRadius:(CGFloat)cornerRadius
                     tintColor:(nullable UIColor *)tintColor
                         alpha:(CGFloat)alpha {
    // Remove existing effect if any
    [self removeLiquidGlassEffect];

    // Determine blur effect style based on liquid glass style
    UIBlurEffectStyle blurStyle;
    switch (style) {
        case LiquidGlassStyleLight:
            blurStyle = UIBlurEffectStyleSystemThinMaterialLight;
            break;
        case LiquidGlassStyleDark:
            blurStyle = UIBlurEffectStyleSystemThinMaterialDark;
            break;
        case LiquidGlassStyleUltraThin:
            blurStyle = UIBlurEffectStyleSystemUltraThinMaterial;
            break;
        case LiquidGlassStyleProminent:
            blurStyle = UIBlurEffectStyleSystemMaterial;
            break;
        default:
            blurStyle = UIBlurEffectStyleSystemMaterial;
            break;
    }

    // Create blur effect
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = self.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurView.alpha = alpha;

    // Apply corner radius
    blurView.layer.cornerRadius = cornerRadius;
    blurView.layer.cornerCurve = kCACornerCurveContinuous;
    blurView.layer.masksToBounds = YES;

    // Add vibrancy effect on top
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect style:UIVibrancyEffectStyleLabel];
    UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    vibrancyView.frame = blurView.bounds;
    vibrancyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [blurView.contentView addSubview:vibrancyView];

    // Add custom tint if provided
    if (tintColor) {
        UIView *tintView = [[UIView alloc] initWithFrame:blurView.bounds];
        tintView.backgroundColor = tintColor;
        tintView.alpha = 0.3;
        tintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [blurView.contentView insertSubview:tintView atIndex:0];
    }

    // Insert at the back
    [self insertSubview:blurView atIndex:0];

    // Store reference for later removal
    objc_setAssociatedObject(self, &kLiquidGlassEffectViewKey, blurView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Apply subtle shadow for depth
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 12;
    self.layer.shadowOpacity = 0.15;

    // Ensure corner radius is applied to the main view
    self.layer.cornerRadius = cornerRadius;
    self.layer.cornerCurve = kCACornerCurveContinuous;
    self.clipsToBounds = NO; // Don't clip for shadow
}

- (void)removeLiquidGlassEffect {
    UIView *existingBlurView = objc_getAssociatedObject(self, &kLiquidGlassEffectViewKey);
    if (existingBlurView) {
        [existingBlurView removeFromSuperview];
        objc_setAssociatedObject(self, &kLiquidGlassEffectViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // Remove shadow
    self.layer.shadowOpacity = 0;
}

- (void)addGlassBorderWithColors:(NSArray<UIColor *> *)colors width:(CGFloat)width {
    // Remove existing border layer
    CAGradientLayer *existingBorder = objc_getAssociatedObject(self, &kLiquidGlassBorderLayerKey);
    if (existingBorder) {
        [existingBorder removeFromSuperlayer];
    }

    // Create gradient layer for the border
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.bounds;
    gradientLayer.cornerRadius = self.layer.cornerRadius;
    gradientLayer.cornerCurve = kCACornerCurveContinuous;

    // Convert UIColors to CGColors
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:colors.count];
    for (UIColor *color in colors) {
        [cgColors addObject:(__bridge id)color.CGColor];
    }
    gradientLayer.colors = cgColors;

    // Diagonal gradient
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 1);

    // Create mask for the border
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.bounds;

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRoundedRect(path, NULL, self.bounds, self.layer.cornerRadius, self.layer.cornerRadius);

    CGRect innerRect = CGRectInset(self.bounds, width, width);
    CGPathAddRoundedRect(path, NULL, innerRect, self.layer.cornerRadius - width, self.layer.cornerRadius - width);

    maskLayer.path = path;
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    CGPathRelease(path);

    gradientLayer.mask = maskLayer;

    [self.layer addSublayer:gradientLayer];

    // Store reference
    objc_setAssociatedObject(self, &kLiquidGlassBorderLayerKey, gradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)animateGlassAppearanceWithDuration:(NSTimeInterval)duration {
    self.alpha = 0;
    self.transform = CGAffineTransformMakeScale(0.9, 0.9);

    [UIView animateWithDuration:duration
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.alpha = 1.0;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)addFloatingAnimation {
    [self removeFloatingAnimation];

    CABasicAnimation *floatAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    floatAnimation.fromValue = @(0);
    floatAnimation.toValue = @(-8);
    floatAnimation.duration = 2.0;
    floatAnimation.autoreverses = YES;
    floatAnimation.repeatCount = HUGE_VALF;
    floatAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    [self.layer addAnimation:floatAnimation forKey:@"floatingAnimation"];
}

- (void)removeFloatingAnimation {
    [self.layer removeAnimationForKey:@"floatingAnimation"];
}

@end
