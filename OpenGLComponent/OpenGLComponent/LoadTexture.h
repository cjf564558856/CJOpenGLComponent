//
//  LoadTexture.h
//  OpenGLComponent
//
//  Created by 陈济峰 on 2021/2/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoadTexture : UIView

/**
根据图片名称加载纹理
 
 */
- (void)LoadTextureWithImgaeName:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
