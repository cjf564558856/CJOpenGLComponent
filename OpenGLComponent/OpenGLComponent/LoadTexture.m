//
//  LoadTexture.m
//  OpenGLComponent
//
//  Created by 陈济峰 on 2021/2/3.
//

#import "LoadTexture.h"
#import <OpenGLES/ES2/gl.h>
#import "CompileLinkProgrem.h"
#import "DataTransport.h"


//加载纹理步骤：
//1.创建图层
//2.创建上下文
//3.清空缓存区
//4.设置RenderBuffer
//5.设置FrameBuffer
//6.开始绘制

//需要注意：纹理加载后是倒置的，需要翻转
//翻转纹理方式：
//1.提供相反的纹理坐标和顶点坐标
//2.顶点着色器fsh翻转
//3.片元着色器vsh翻转
//4.投影视图矩阵加入旋转矩阵
//5.绘制位图时直接翻转(一般采用这种)

@interface LoadTexture ()

//在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
@property(nonatomic,strong)CAEAGLLayer *myEagLayer;//需要对应的layer才能绘制
@property(nonatomic,strong)EAGLContext *myContext;//上下文信息
@property(nonatomic,assign)GLuint myColorRenderBuffer;//RenderBuffer
@property(nonatomic,assign)GLuint myColorFrameBuffer;//FrameBuffer
@property(nonatomic,assign)GLuint myPrograme;//程序id
@property (nonatomic , strong) NSString *imageName;

@end

@implementation LoadTexture

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (void)LoadTextureWithImgaeName:(NSString *)imageName{
    
//    先从从图片中加载纹理
    self.imageName = imageName;
    
    //1.设置图层
    [self setupLayer];
    
    //2.设置图形上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deleteRenderAndFrameBuffer];
    
    //4.设置RenderBuffer
    [self setupRenderBuffer];
    
    //5.设置FrameBuffer
    [self setupFrameBuffer];
    
    //6.开始绘制
    [self renderLayer];
}

//从图片中加载纹理
- (GLuint)setupTexture:(NSString *)fileName {
    
    //1、将 UIImage 转换为 CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    
    //判断图片是否获取成功
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    //2、读取图片的大小，宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //3.获取图片字节数 宽*高*4（RGBA）
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
    
    //4.创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    

    //5、在CGContextRef上--> 将图片绘制出来
    /*
     CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
     CGContextDrawImage
     参数1：绘图上下文
     参数2：rect坐标
     参数3：绘制的图片
     */
    CGRect rect = CGRectMake(0, 0, width, height);
   
    //6.使用默认方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
   
    //绘制位图时候就翻转
    CGContextTranslateCTM(spriteContext, rect.origin.x, rect.origin.y);
    CGContextTranslateCTM(spriteContext, 0, rect.size.height);
    CGContextScaleCTM(spriteContext, 1.0, -1.0);
    CGContextTranslateCTM(spriteContext, -rect.origin.x, -rect.origin.y);
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //7、画图完毕就释放上下文
    CGContextRelease(spriteContext);
    
    //8、绑定纹理到默认的纹理ID（
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //9.设置纹理属性
    /*
     参数1：纹理维度
     参数2：线性过滤、为s,t坐标设置模式
     参数3：wrapMode,环绕模式
     */
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
    //10.载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    //11.释放spriteData
    free(spriteData);
    return 0;
}


//1.设置图层
- (void)setupLayer{
    //1.创建特殊图层
    /*
     重写layerClass，将返回的图层从CALayer替换成CAEAGLLayer
     */
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    
    //2.设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];

    //3.设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
    /*
     kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
     kEAGLDrawablePropertyColorFormat
         可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
     
         kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
         kEAGLColorFormatRGB565：16位RGB的颜色，
         kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
     */
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false,kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
}

//2.设置上下文
- (void)setupContext{
    //1.指定OpenGL ES 渲染API版本，我们使用2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    //2.创建图形上下文
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:api];
    //3.判断是否创建成功
    if (!context) {
        NSLog(@"Create context failed!");
        return;
    }
    //4.设置图形上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"setCurrentContext failed!");
        return;
    }
    //5.将局部context，变成全局的
    self.myContext = context;
}

//3.清空缓存区
- (void)deleteRenderAndFrameBuffer{
    /*
     buffer分为frame buffer 和 render buffer2个大类。
     其中frame buffer 相当于render buffer的管理者。
     frame buffer object即称FBO。
     render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
     */
    
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

//4.设置RenderBuffer
- (void)setupRenderBuffer{
    //1.定义一个缓存区ID
    GLuint buffer;
    
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    
    //3.赋值buffer
    self.myColorRenderBuffer = buffer;
    
    //4.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //5.将可绘制对象drawable object's  CAEAGLLayer的存储绑定到OpenGL ES renderBuffer对象
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

//5.设置FrameBuffer
- (void)setupFrameBuffer{
    //1.定义一个缓存区ID
    GLuint buffer;
    
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    
    //3.赋值buffer
    self.myColorFrameBuffer = buffer;
    
    //4.将标识符绑定到GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    /*生成帧缓存区之后，则需要将renderbuffer跟framebuffer进行绑定，
     调用glFramebufferRenderbuffer函数进行绑定到对应的附着点上，后面的绘制才能起作用
     */
    //5.将渲染缓存区myColorRenderBuffer 通过glFramebufferRenderbuffer函数绑定到 GL_COLOR_ATTACHMENT0上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

//6.开始绘制
- (void)renderLayer{
    //设置清屏颜色
    glClearColor(0.3f, 0.45f, 0.5f, 1.0f);
    //清除屏幕
    glClear(GL_COLOR_BUFFER_BIT);
    
    //1.设置视口大小
    CGFloat scale = [[UIScreen mainScreen]scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    self.myPrograme = [CompileLinkProgrem programWithShaderName:@"shader"];
  
    //5.使用program
    glUseProgram(self.myPrograme);
    
    //6.设置顶点、纹理坐标
    [DataTransport vertexDateWithProgrem:self.myPrograme];
    [DataTransport textureDateWithProgrem:self.myPrograme];

    
    //10.加载纹理
    [self setupTexture:self.imageName];
    
    //11. 设置纹理采样器 sampler2D
    glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
    
    //12.绘图
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    //13.从渲染缓存区显示到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

@end
