#include "include/raylib.h"
 void RealLoadFontEx(const char* fileName, int fontSize, int*fontChars, int glyphCount,Font* dst){
    *dst = LoadFontEx(fileName,fontSize,fontChars,glyphCount);
}
// void PrintVector(Vector2 vec){
//     printf("%f, %f\n",vec.x,vec.y);
// }
// void PrintText(Font* font){
//     Vector2 vec = {0.0f,0.0f};
//     Color color = {255,255,255,255};
//     DrawTextEx(*font,"Hello, from C from assembly!",vec,16.0f,0.0f,color);
// }