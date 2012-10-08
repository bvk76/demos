
/*
   Arturo Cepeda P�rez

	Rendering Engine (OpenGL)

   --- GERenderingObjects.h ---
*/

#ifndef _GERENDERINGOBJECTS_H_
#define _GERENDERINGOBJECTS_H_

#include "GEDevice.h"
#include "Texture2D.h"
#include <OpenGLES/EAGL.h>
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

#define ZNEAR  0.1f
#define ZFAR   1000.0f
#define PI     3.14159f

struct GEColor
{
    float R;
    float G;
    float B;

    GEColor()
    {
        set(1.0f, 1.0f, 1.0f);
    }

    GEColor(float cR, float cG, float cB)
    {
        set(cR, cG, cB);
    }

    void set(float cR, float cG, float cB)
    {
       R = cR;
       G = cG;
       B = cB;
    }
};

struct GEVector
{
    float X;
    float Y;
    float Z;

    GEVector()
    {
        set(0.0f, 0.0f, 0.0f);
    }

    GEVector(float vX, float vY, float vZ)
    {
        set(vX, vY, vZ);
    }

    void set(float vX, float vY, float vZ)
    {
        X = vX;
        Y = vY;
        Z = vZ;
    }
};

struct GETextureSize
{
   unsigned int Width;
   unsigned int Height;
};

class GERenderingObject
{
protected:
   GEVector vPosition;
   GEVector vRotation;
   GEVector vScale;
   GEColor cColor;
   float fOpacity;
   bool bVisible;
   
   void loadTexture(GLuint iTexture, NSString* sName);

public:
   void move(float DX, float DY, float DZ);
   void move(const GEVector& Move);
   void scale(float SX, float SY, float SZ);
   void scale(const GEVector& Scale);
   void rotate(float RX, float RY, float RZ);
   void rotate(const GEVector& Rotate);
   void show();
   void hide();
   
   virtual void render() = 0;

   void getPosition(GEVector* Position);
   void getRotation(GEVector* Rotation);
   void getScale(GEVector* Scale);
   float getOpacity();
   bool getVisible();   

   void setPosition(float X, float Y, float Z = 0.0f);
   void setPosition(const GEVector& Position);
   void setScale(float X, float Y, float Z = 1.0f);
   void setScale(const GEVector& Scale);
   void setRotation(float X, float Y, float Z);
   void setRotation(const GEVector& Rotation);
   void setColor(float R, float G, float B);
   void setColor(const GEColor& Color);
   void setOpacity(float Opacity);
   void setVisible(bool Visible);
};

class GEMesh : public GERenderingObject
{
private:
   unsigned int iNumVertices;
   float* fVertex;
   float* fNormals;
   
   GLuint tTexture;
   float* fTextureCoordinate;
   
   GEVector vCenter;
   
public:
   GEMesh();
   ~GEMesh();

   void loadFromHeader(unsigned int NumVertices, float* Vertex, float* Normals);
   void loadFromHeader(unsigned int NumVertices, float* Vertex, float* Normals, 
                       GLuint Texture, float* TextureCoordinate);
   void unload();

   void render();
};


class GESprite : public GERenderingObject
{
private:
   GLuint tTexture;
   GEVector vCenter;   
   float fTextureCoordinates[8];

public:
   GESprite(GLuint Texture, const GETextureSize& TextureSize);
   ~GESprite();

   void loadFromFile(const char* Filename);
   void unload();

   void render();

   void setCenter(float X, float Y, float Z);
   void setTextureCoordinates(float Ax, float Ay, float Bx, float By,
                              float Cx, float Cy, float Dx, float Dy);
};


class GELabel : public GERenderingObject
{
private:
   Texture2D* tTexture;
   UITextAlignment tAligment;
   
public:
   GELabel(NSString* Text, NSString* FontName, float FontSize, UITextAlignment TextAligment,
           unsigned int TextureSize);
   ~GELabel();
   
   void render();
};


class GECamera
{
private:
    // camera vectors
	GEVector vEye;
	GEVector vAngle;

public:
   GECamera();
   ~GECamera();
   
   void move(float DX, float DY, float DZ);
   void move(const GEVector& Move);
   
   void lookAt(float X, float Y, float Z);
   void lookAt(const GEVector& LookAt);
   
   void setPosition(float X, float Y, float Z);
   void setPosition(const GEVector& Position);    
   
   void setAngle(float X, float Y, float Z);
   void setAngle(const GEVector& Angle);

   void use();
};

#endif