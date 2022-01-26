#include <stdio.h>
#include "include/raylib.h"
int main()  {
    Shader shad;
    printf("sizeof(int) -> %d\n",sizeof(int));
    printf("Shader {\nuint id -> %d\nint* locs -> %d\n} -> sizeof(%d)\n",(char*)&(shad.id) - (char*)&shad,(char*)&(shad.locs) - (char*)&shad,sizeof(shad));
    Font font;
    // printf("Font {\nint baseSize -> %d\nint glyphCount -> %d\nint glyphPadding -> %d\nTexture2D texture {\n\tunsigned int -> %d\n\tint width -> %d\n\tint height -> %d\n\tint mipmaps -> %d\n\tint format -> %d\n} -> %d\nRectangle* recs -> %d\nGlyphInfo* glyphs -> %d\n} -> %d\n",&font.glyphCount-&font,&font.glyphPadding-&font.glyphCount,)
    printf("Font -> %ld\n",sizeof(font));
    return 0;
}