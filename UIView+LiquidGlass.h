//
//  UIView+LiquidGlass.h
//  ImgurViewer
//
//  Created for iOS 15+ modernization - 2025
//  Liquid glass (glassmorphism) effects for modern iOS
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LiquidGlassStyle) {
    LiquidGlassStyleLight,      // Light glass effect
    LiquidGlassStyleDark,       // Dark glass effect
    LiquidGlassStyleUltraThin,  // Ultra-thin material
    LiquidGlassStyleProminent   // Prominent material
};

@interface UIView (LiquidGlass)

/**
 * Apply liquid glass effect with blur and vibrancy
 * @param style The glass style to apply
 * @param cornerRadius Corner radius for the glass effect
 */
- (void)applyLiquidGlassEffect:(LiquidGlassStyle)style cornerRadius:(CGFloat)cornerRadius;

/**
 * Apply liquid glass effect with custom tint color
 * @param style The glass style to apply
 * @param cornerRadius Corner radius for the glass effect
 * @param tintColor Custom tint color for the glass
 * @param alpha Transparency level (0.0 - 1.0)
 */
- (void)applyLiquidGlassEffect:(LiquidGlassStyle)style
                  cornerRadius:(CGFloat)cornerRadius
                     tintColor:(nullable UIColor *)tintColor
                         alpha:(CGFloat)alpha;

/**
 * Remove liquid glass effect
 */
- (void)removeLiquidGlassEffect;

/**
 * Add subtle gradient border (part of liquid glass aesthetic)
 */
- (void)addGlassBorderWithColors:(NSArray<UIColor *> *)colors width:(CGFloat)width;

/**
 * Animate liquid glass appearance
 */
- (void)animateGlassAppearanceWithDuration:(NSTimeInterval)duration;

/**
 * Apply floating animation (subtle up/down motion)
 */
- (void)addFloatingAnimation;

/**
 * Remove floating animation
 */
- (void)removeFloatingAnimation;

@end

NS_ASSUME_NONNULL_END
