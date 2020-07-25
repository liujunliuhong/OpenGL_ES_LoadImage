//
//  ViewController.m
//  OpenGL_ES_LoadImage
//
//  Created by apple on 2020/7/25.
//  Copyright © 2020 yinhe. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface ViewController () <GLKViewDelegate>
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupConfig];
    [self setupVertexData];
    [self setupTexture];
}

// 配置基本信息
- (void)setupConfig{
    // 使用OpenGLES3
    // EAGLContext是苹果iOS平台下实现OpenGLES渲染层
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    // 判断是否创建成功
    if (!self.context) {
        NSLog(@"Create ES context failed");
        return;
    }
    
    // 设置当前上下文
    [EAGLContext setCurrentContext:self.context];
    
    
    // 获取GLKView
    GLKView *glkView = (GLKView *)self.view; // 因为当前VC是继承自`GLKViewController`，所有可以这样直接获取
    glkView.delegate = self;
    
    // 设置`GLKView`的`context`
    glkView.context = self.context;
    
    // 配置视图渲染缓冲区
    glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    // 设置背景颜色
    glClearColor(1, 0, 0, 1);
}

// 配置顶点数据
- (void)setupVertexData{
    // 每一行的前面3个是顶点坐标，后面2个是纹理坐标
    // 纹理坐标系取值范围[0,1];原点是左下角(0,0);
    // 故而(0,0)是纹理图像的左下角, 点(1,1)是右上角.
    GLfloat vertexData[] = {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5,  0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
    
    
    /*
     顶点数组: 开发者可以选择设定函数指针，在调用绘制方法的时候，直接由内存传入顶点数据，也就是说这部分数据之前是存储在内存当中的，被称为顶点数组
     顶点缓存区: 性能更高的做法是，提前分配一块显存，将顶点数据预先传入到显存当中。这部分的显存，就被称为顶点缓冲区
     */
    
    // 开辟顶点缓冲区
    // (1) 创建顶点缓冲区标识符ID
    GLuint bufferID;
    glGenBuffers(1, &bufferID); // 开辟1个顶点缓冲区，所以传入1
    NSLog(@"bufferID:%d", bufferID);
    // (2) 绑定顶点缓冲区
    glBindBuffer(GL_ARRAY_BUFFER, bufferID);
    // (3) 将顶点数组的数据copy到顶点缓冲区中(GPU显存中)
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    
    // 打开读取通道
    /*
     在iOS中, 默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的.
     意味着,顶点数据在着色器端(服务端)是不可用的. 即使你已经使用glBufferData方法,将顶点数据从内存拷贝到顶点缓存区中(GPU显存中).
     所以, 必须由glEnableVertexAttribArray 方法打开通道.指定访问属性.才能让顶点着色器能够访问到从CPU复制到GPU的数据.
     注意: 数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
     */
    
    /*
     glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)
     
      功能: 上传顶点数据到显存的方法（设置合适的方式从buffer里面读取数据）
      参数列表:
          index,指定要修改的顶点属性的索引值,例如
          size, 每次读取数量。（如position是由3个（x,y,z）组成，而颜色是4个（r,g,b,a）,纹理则是2个.）
          type,指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
          normalized,指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
          stride,指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0
          ptr指定一个指针，指向数组中第一个顶点属性的第一个组件。初始值为0
     */
    glEnableVertexAttribArray(GLKVertexAttribPosition); // 顶点坐标数据
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); // 纹理坐标数据
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3); // 第一个纹理坐标前面有3个值，是顶点坐标
    
}

// 配置纹理
- (void)setupTexture{
    // 获取纹理图片
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"png"];
    
    // 初始化纹理
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft: @(1)}; // 纹理坐标原点是左下角,但是图片显示原点应该是左上角
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    NSLog(@"textureInfo.name: %d", textureInfo.name);
    
    // 使用苹果`GLKit`提供的`GLKBaseEffect`完成着色器工作(顶点/片元)
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.enabled = GL_TRUE;
    self.baseEffect.texture2d0.name = textureInfo.name;
    
    
//    CGFloat aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
//    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 0.1, 100.0);
//    self.baseEffect.transform.projectionMatrix = projectionMatrix;
//
//    GLKMatrix4 modelviewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -4.0);
//    self.baseEffect.transform.modelviewMatrix = modelviewMatrix;
}


#pragma mark GLKViewDelegate
// 绘制视图的内容
// `GLKView`对象使其`OpenGL ES`上下文成为当前上下文，并将其`framebuffer`绑定为`OpenGL ES`呈现命令的目标。然后，委托方法应该绘制视图的内容。
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    // 清除颜色缓冲区
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 准备绘制
    [self.baseEffect prepareToDraw];
    
    // 开始绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
}

@end
