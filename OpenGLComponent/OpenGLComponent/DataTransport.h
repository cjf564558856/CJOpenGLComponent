//
//  DataTransport.h
//  OpenGLComponent
//
//  Created by 陈济峰 on 2021/2/3.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataTransport : NSObject

/**
将顶点数组拷贝到顶点缓冲区
 
 @param progrem 着色器程序的 ID
 */
+ (void)vertexDateWithProgrem:(GLuint)progrem;


/**
读取纹理数据
 
 @param progrem 着色器程序的 ID
 */
+ (void)textureDateWithProgrem:(GLuint)progrem;


@end

NS_ASSUME_NONNULL_END
