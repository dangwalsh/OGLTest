//
//  Shader.fsh
//  Game
//
//  Created by Daniel Walsh on 8/29/12.
//  Copyright (c) 2012 Daniel Walsh. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
