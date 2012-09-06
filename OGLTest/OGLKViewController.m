//
//  OGLKViewController.m
//  OGLTest
//
//  Created by Daniel Walsh on 8/29/12.
//  Copyright (c) 2012 Daniel Walsh. All rights reserved.
//

#import "OGLKViewController.h"
#import "PointIndex.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface OGLKViewController () {
    GLuint _program;
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    GLKMatrix4 _rotMatrix;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexArray;
    float _rotation;
    BOOL _touch;
    
    NSUInteger tapCount;
    NSTimeInterval delay;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation OGLKViewController
/*
typedef struct {
    
    float Position[3];
    float Normal[3];
    
}Vertex;

Vertex Vertices[576];
GLubyte Indices[3456];
*/

GLfloat gVertexData[21000];

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];    
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad  //create context and view
{
    [super viewDidLoad];
    
    tapCount = 0;
    delay = 2;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    NSString *objPathname = [[NSBundle mainBundle] pathForResource:@"polyhedron3" ofType:@"obj"];
    if (!objPathname) {
        NSLog(@"Failed to get bundle");
    }
    [self loadObj:objPathname];
    
    [self setupGL];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - openGL methods

- (void)setupGL //create shader, vertex buffer objects, and attribute pointers
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(0.4f, 0.4f, 1.0f, 1.0f);
/*
    glEnable(GL_DEPTH_TEST);

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Position));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Normal));
    
    _rotMatrix = GLKMatrix4Identity;
*/
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gVertexData), gVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
    
    _rotMatrix = GLKMatrix4Identity;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];

    glDeleteBuffers(1, &_vertexBuffer);
    //glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (void)update //setup transformation matrices
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 1.0f, 10.0f);

    self.effect.transform.projectionMatrix = projectionMatrix;

    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, _rotMatrix);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect  //do the drawing
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    [self.effect prepareToDraw];
    
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);

    //glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    glDrawArrays(GL_LINES, 0,3600);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Vertex" ofType:@"glsl"];
    if (!vertShaderPathname) {
        NSLog(@"Failed to get bundle");
    }
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Fragment" ofType:@"glsl"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

# pragma mark - Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if (touch.tapCount == 2){
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if (touch.tapCount == 1) {
        [self performSelector: @selector(singleTap)
                   withObject:nil
                   afterDelay:delay];
    } else if (touch.tapCount == 2) {
        [self doubleTap];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    CGPoint lastLoc = [touch previousLocationInView:self.view];
    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
    
    float rotX = -1 * GLKMathDegreesToRadians(diff.y / 2.0);
    float rotY = -1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
    bool isInvertible;
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
                                                 GLKVector3Make(1, 0, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
                                                 GLKVector3Make(0, 1, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
    
}

- (void)noTap {
    tapCount = 0;
}

- (void)singleTap {
    tapCount = 1;    
    [self performSelector:@selector(noTap)
               withObject:nil
               afterDelay:delay];
}

- (void)doubleTap {
    tapCount = 2;
    [self performSelector:@selector(noTap)
               withObject:nil
               afterDelay:delay];
}


#pragma mark - Load Objects

- (void)loadObj: (NSString *)_filepath
{
    NSMutableArray *vertices = [[NSMutableArray alloc]init];
    NSMutableArray *normals = [[NSMutableArray alloc]init];
//    NSMutableArray *coords = [[NSMutableArray alloc]init];
//    NSMutableArray *coordsIndex = [[NSMutableArray alloc]init];
//    NSMutableDictionary *faceIndex = [[NSMutableDictionary alloc]init];
//    NSMutableArray *faceArray = [[NSMutableArray alloc]init];
    NSMutableArray *pointArray = [[NSMutableArray alloc]init];
    
    NSString *contents = [NSString stringWithContentsOfFile:_filepath encoding:NSUTF8StringEncoding error:nil];
    NSArray * lines = [contents componentsSeparatedByString:@"\n"];
    
    for (NSString *line in lines) {
        if (line.length < 1)
            continue;
        NSArray * values = [line componentsSeparatedByString:@" "];        
        if ([(NSString *)[values objectAtIndex:0] isEqualToString:@"v"]) {
            NSMutableArray *vertex = [[NSMutableArray alloc]initWithCapacity:3];
            for (int i = 1; i < 4; i++) {
                [vertex addObject:[values objectAtIndex:i]];
            }
            [vertices addObject:vertex];
            //check to see if it's possible to just remove "v" from the existing array then add it to vertices
        }
        else if ([(NSString *)[values objectAtIndex:0] isEqualToString:@"vn"]) {
            NSMutableArray *normal = [[NSMutableArray alloc]initWithCapacity:3];
            for (int i = 1; i < 4; i++) {
                [normal addObject:[values objectAtIndex:i]];
            }
            [normals addObject:normal];
            //check to see if it's possible to just remove "vn" from the existing array then add it to normals
        }
/*        else if([(NSString *)[values objectAtIndex:0] isEqualToString:@"vt"]){
            NSMutableArray *coord = [[NSMutableArray alloc]initWithCapacity:2];
            for (int i = 1; i < 3; i++) {
                [coord addObject:[values objectAtIndex:i]];
            }
            [coords addObject:coord];
        }
*/        else if ([(NSString *)[values objectAtIndex:0] isEqualToString:@"f"]) {
            for (int i = 1; i < 4; i++) {
                NSArray *face = [(NSString *)[values objectAtIndex:i] componentsSeparatedByString:@"/"];
                //[faceIndex setValue:[face objectAtIndex:2] forKey:[face objectAtIndex:0]];
                //[faceArray addObject:[face objectAtIndex:0]];
                
                PointIndex *index = [[PointIndex alloc]init];
                index.vertex = [[face objectAtIndex:0] intValue] - 1;
                index.normal = [[face objectAtIndex:2] intValue] - 1;
                [pointArray addObject:index];
            }            
        }
    }
    int i = 0;
    for (PointIndex *pt in pointArray) {
        
        gVertexData[i]   = [[[vertices objectAtIndex:pt.vertex] objectAtIndex:0] floatValue];
        gVertexData[i+1] = [[[vertices objectAtIndex:pt.vertex] objectAtIndex:1] floatValue];
        gVertexData[i+2] = [[[vertices objectAtIndex:pt.vertex] objectAtIndex:2] floatValue];
        
        gVertexData[i+3] = [[[normals objectAtIndex:pt.normal] objectAtIndex:0] floatValue];
        gVertexData[i+4] = [[[normals objectAtIndex:pt.normal] objectAtIndex:1] floatValue];
        gVertexData[i+5] = [[[normals objectAtIndex:pt.normal] objectAtIndex:2] floatValue];
        
        i+=6;
    }
    /*
    int i = 0;
    for (NSMutableArray *vert in vertices) {
        Vertices[i].Position[0] = [[vert objectAtIndex:0] floatValue];
        Vertices[i].Position[1] = [[vert objectAtIndex:1] floatValue];
        Vertices[i].Position[2] = [[vert objectAtIndex:2] floatValue];        
        int normalIndex = [[faceIndex objectForKey:[NSString stringWithFormat:@"%i",i+1]] intValue];
        --normalIndex;
        Vertices[i].Normal[0] = [[[normals objectAtIndex:normalIndex] objectAtIndex:0] floatValue];
        Vertices[i].Normal[1] = [[[normals objectAtIndex:normalIndex] objectAtIndex:1] floatValue];
        Vertices[i].Normal[2] = [[[normals objectAtIndex:normalIndex] objectAtIndex:2] floatValue];
        ++i;
    }
    
    for (int i = 0; i < faceArray.count; ++i) {
        Indices[i] = [[faceArray objectAtIndex:i] intValue] - 1;
    }
     */
 
}

@end
