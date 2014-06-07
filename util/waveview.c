#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <limits.h>
#if (__APPLE__ & __MACH__)
  #include <GLUT/glut.h>
#else
  #include <GL/glut.h>
#endif

#include "common.h"
#include "hdf5rawWaveformIo.h"

#define MAX_FRAMES_PER_BUFFER 1024
float rawmin, rawmax, rawavg, rawamp;
float ps_out[MAX_FRAMES_PER_BUFFER], psmin, psmax, psavg, psamp;
GLfloat colors[][4] = {
    {1.0, 0.0, 0.0, 0.5},
    {0.0, 1.0, 0.0, 0.5},
    {0.0, 0.0, 1.0, 0.8},
    {1.0, 1.0, 0.0, 0.5},
    {0.0, 1.0, 1.0, 0.5},
    {1.0, 0.0, 1.0, 0.5},
    {0.2, 1.0, 0.3, 0.5},
    {1.0, 0.2, 0.3, 0.5},
    {1.0, 1.0, 1.0, 0.5},    
};

#define INIT_WINDOW_WIDTH 1600
#define INIT_WINDOW_HEIGHT 1000
#define HEAD_FRAC 0.02
size_t winW, winH;
ssize_t xL=0, xH=0;
size_t nChDisp;

struct ch_disp_info
{
    double min[SCOPE_NCH];
    double max[SCOPE_NCH];
    double mean[SCOPE_NCH];
    double ydl[SCOPE_NCH]; /* y display low */
    double ydh[SCOPE_NCH]; /* y display high */
};
double digestL, digestH;
struct ch_disp_info chdInfo;
struct hdf5io_waveform_file *wavFile;
struct waveform_attribute wavAttr;
struct hdf5io_waveform_event wavEvent;

char *dumpFileName = "out.dat";
size_t nEventsInFile;
size_t wavDigestLen = GL_MAX_VIEWPORT_DIMS;
SCOPE_DATA_TYPE *wavDigest=NULL; /* scaled down (in x) version of wavBuf for overall display */

/**************************** data stuff ************************************/
void data_get_event(size_t iEvent)
{
    wavEvent.eventId = iEvent;
    hdf5io_read_event(wavFile, &wavEvent);
}

void data_update_digest(void)
{
    ssize_t iCh, i, j;
    size_t n;
    double s, m;
    SCOPE_DATA_TYPE l, h, v;
    
    s = wavFile->nPt / (double)wavDigestLen;
    
    for(iCh=0; iCh < wavFile->nCh; iCh++) {
        /* update chdInfo */
        v = wavEvent.wavBuf[wavFile->nPt * iCh];
        chdInfo.min[iCh] = chdInfo.max[iCh] = v;
        chdInfo.mean[iCh] = 0.0;
        for(i=0; i < wavFile->nPt; i++) {
            v = wavEvent.wavBuf[wavFile->nPt * iCh + i];
            if(v < chdInfo.min[iCh]) chdInfo.min[iCh] = v;
            if(v > chdInfo.max[iCh]) chdInfo.max[iCh] = v;
            chdInfo.mean[iCh] += v;
        }
        chdInfo.mean[iCh] /= (double)(wavFile->nPt);
        /* update digest */
        for(j=0; j < wavDigestLen; j++) {
            m = 0.0;
            n = 0;
            i = (j*s);
            v = wavEvent.wavBuf[wavFile->nPt * iCh + i];
            l = v;
            h = v;
            for(i = (j*s); i < (j+1)*s; i++) {
                v = wavEvent.wavBuf[wavFile->nPt * iCh + i];
                m += (double)v;
                n++;
                if(v < l) l = v;
                if(v > h) h = v;
            }
            m /= (double)n;
            wavDigest[wavDigestLen * iCh + j] = m;
        }
        printf("Ch%zd: min: %g, max: %g, mean: %g\n", iCh,
               chdInfo.min[iCh], chdInfo.max[iCh], chdInfo.mean[iCh]);
        if(iCh == 0) {
            digestL = chdInfo.min[iCh];
            digestH = chdInfo.max[iCh];
        } else {
            if(chdInfo.min[iCh] < digestL) digestL = chdInfo.min[iCh];
            if(chdInfo.max[iCh] > digestH) digestH = chdInfo.max[iCh];
        }
    }
}
void dump_to_file(char *fname)
{
    ssize_t i, iCh;
    FILE *fp;
    if((fp=fopen(fname, "w"))==NULL) {
        perror(fname);
        return;
    }
    for(i=xL; i<xH; i++) {
        fprintf(fp, "%9zd", i);
        for(iCh = 0; iCh < wavFile->nCh; iCh++) {
            fprintf(fp, " %-6d", wavEvent.wavBuf[wavFile->nPt * iCh + i]);
        }
        fprintf(fp, "\n");
    }
    fclose(fp);
    printf("data dumped to %s\n", fname);
}

/****************************   GL stuff ************************************/
void change_size(int w, int h)
{
    winW = w;
    winH = h;
    glViewport(0, 0, (GLsizei) w, (GLsizei) h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluOrtho2D(0.0, (GLdouble)SCOPE_MEM_LENGTH_MAX, 0.0, (GLdouble) h);
    glutPostRedisplay();
}
void process_normal_keys(unsigned char key, int x, int y)
{
    switch(key) {
    case 27:
		exit(0);
        break;
    case ' ':
        dump_to_file(dumpFileName);
        break;
    case '-':
        xL--;
        if(xL < 0) xL = 0;
        break;        
    case '[':
        xL -= 0.01 * wavFile->nPt;
        if(xL < 0) xL = 0;
        break;
    case '=':
        xL++;
        if(xL > xH) xL = xH;
        break;
    case ']':
        xL += 0.01 * wavFile->nPt;
        if(xL > xH) xL = xH;
        break;
    case '_':
        xH--;
        if(xH < xL) xH = xL;
        break;        
    case '{':
        xH -= 0.01 * wavFile->nPt;
        if(xH < xL) xH = xL;
        break;
    case '+':
        xH++;
        if(xH >= wavFile->nPt)
            xH = wavFile->nPt - 1;
        break;
    case '}':
        xH += 0.01 * wavFile->nPt;
        if(xH >= wavFile->nPt)
            xH = wavFile->nPt - 1;
        break;
    default:
        break;
    }
    printf("xL = %zd, xH = %zd\n", xL, xH);
    glutPostRedisplay();
}
void process_special_keys(int key, int x, int y)
{
    ssize_t dx;
    int modifier;

    modifier = glutGetModifiers();
    if(modifier & GLUT_ACTIVE_SHIFT) {
        dx = 10;
    } else if(modifier & GLUT_ACTIVE_ALT) {
        dx = 100;
    } else if(modifier & GLUT_ACTIVE_CTRL) {
        dx = 1000;
    } else {
        dx = 1;
    }
    
    switch(key) {
    case GLUT_KEY_LEFT:
        if(xL - dx >= 0) {
            xL -= dx;
            xH -= dx;
        }
        break;
    case GLUT_KEY_RIGHT:
        if(xH+dx < wavFile->nPt) {
            xL += dx;
            xH += dx;
        }
        break;
    default:
        break;
    }
    printf("xL = %zd, xH = %zd\n", xL, xH);
    glutPostRedisplay();    
}
void draw(void)
{
    size_t iCh;
    size_t i, j;
    double amp;
    int index;

    glEnable(GL_LINE_SMOOTH);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glHint(GL_LINE_SMOOTH_HINT, GL_DONT_CARE);
    glLineWidth(0.1);
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClearDepth(1.0); 
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    /* draw digest */
    glViewport(0, 0, winW, winH / (nChDisp + 1.0));
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluOrtho2D(0.0, (GLdouble)wavDigestLen,
               digestL-(digestH-digestL)*HEAD_FRAC, digestH+(digestH-digestL)*HEAD_FRAC);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    glBegin(GL_LINES);
    glColor4fv(colors[8]);
    glVertex2f(0.0, 0.0);
    glVertex2f(wavDigestLen * 1.00, 0.0);
    glEnd();

    for(iCh = 0; iCh < nChDisp; iCh++) {
        glBegin(GL_LINE_STRIP);
        glColor3fv(colors[iCh]);
        for(i=0; i<wavDigestLen; i++)
            glVertex2f(i, wavDigest[wavDigestLen * iCh + i]);
        glEnd();
    }
    
    /* vertical lines showing zooming window */
    glBegin(GL_LINES);
    glColor3fv(colors[8]);
    glVertex2f(xL / (double)wavFile->nPt * wavDigestLen, digestL);
    glVertex2f(xL / (double)wavFile->nPt * wavDigestLen, digestH);
    glVertex2f(xH / (double)wavFile->nPt * wavDigestLen, digestL);
    glVertex2f(xH / (double)wavFile->nPt * wavDigestLen, digestH);
    glEnd();

    glPushMatrix();
    glRasterPos2i(1, digestH-16);
    glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, 'F');
    glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, 'F');
    glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, 'T');
    glPopMatrix();

    /* draw channels */
    for(iCh = 0; iCh < nChDisp; iCh++) {
        glViewport(0, (nChDisp-iCh) * winH / (nChDisp + 1.0), winW, winH / (nChDisp + 1.0));
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        amp = chdInfo.max[iCh] - chdInfo.min[iCh];
        gluOrtho2D((GLdouble)xL, (GLdouble)xH,
                   chdInfo.min[iCh]-amp*HEAD_FRAC, chdInfo.max[iCh]+amp*HEAD_FRAC);

        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();

        glColor3fv(colors[iCh]);
        glBegin(GL_LINE_STRIP);
        for(i=xL; i<xH; i++)
            glVertex2f(i, wavEvent.wavBuf[wavFile->nPt * iCh + i]);
        glEnd();

        glBegin(GL_LINES);
        glColor4fv(colors[iCh]);
        glVertex2f(xL, 0.0);
        glVertex2f(xH, 0.0);
        glEnd();
    }
    
/*
    glPushMatrix();
    glLoadIdentity();
    glTranslatef(1.0f, 187.0f, 0.0);
    glScalef(0.1f, 0.1f, 1.0f);
    glutStrokeCharacter(GLUT_STROKE_MONO_ROMAN, 'A');
    glutStrokeCharacter(GLUT_STROKE_MONO_ROMAN, 'T');
    glutStrokeCharacter(GLUT_STROKE_MONO_ROMAN, 'g');
    glPopMatrix();
*/
    glutSwapBuffers();
}

int main(int argc, char **argv)
{
    char *inFileName;

    inFileName = argv[1];
    nChDisp = 4;
    
    wavFile = hdf5io_open_file_for_read(inFileName);
    hdf5io_read_waveform_attribute_in_file_header(wavFile, &wavAttr);    
    fprintf(stdout, "waveform_file:\n"
            "     nPt     = %zd\n"
            "     nCh     = %zd\n"
            "     nWfmPerChunk = %zd\n"
            "     nEvents = %zd\n",
            wavFile->nPt, wavFile->nCh, wavFile->nWfmPerChunk, wavFile->nEvents);
    fprintf(stdout, "waveform_attribute:\n"
            "     chMask  = 0x%02x\n"
            "     nPt     = %zd\n"
            "     nFrames = %zd\n"
            "     dt      = %g\n"
            "     t0      = %g\n"
            "     ymult   = %g %g %g %g\n"
            "     yoff    = %g %g %g %g\n"
            "     yzero   = %g %g %g %g\n",
            wavAttr.chMask, wavAttr.nPt, wavAttr.nFrames, wavAttr.dt,
            wavAttr.t0, wavAttr.ymult[0], wavAttr.ymult[1], wavAttr.ymult[2],
            wavAttr.ymult[3], wavAttr.yoff[0], wavAttr.yoff[1],
            wavAttr.yoff[2], wavAttr.yoff[3], wavAttr.yzero[0],
            wavAttr.yzero[1], wavAttr.yzero[2], wavAttr.yzero[3]);
    nEventsInFile = hdf5io_get_number_of_events(wavFile);
    wavEvent.wavBuf = (SCOPE_DATA_TYPE*)malloc(
        sizeof(SCOPE_DATA_TYPE) * wavFile->nPt * wavFile->nCh);
    wavDigest = (SCOPE_DATA_TYPE*)malloc(sizeof(SCOPE_DATA_TYPE) * wavDigestLen * wavFile->nCh);

    xL = 0;
    xH = MIN(wavFile->nPt, INIT_WINDOW_WIDTH);
    
    data_get_event(0);
    data_update_digest();
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DEPTH|GLUT_DOUBLE|GLUT_RGBA);
    glutInitWindowPosition(-1, -1);
    glutInitWindowSize(INIT_WINDOW_WIDTH, INIT_WINDOW_HEIGHT);
    glutCreateWindow("waveview");
    glutDisplayFunc(draw);
//    glutIdleFunc(draw);
    glutReshapeFunc(change_size);
    glutKeyboardFunc(process_normal_keys);
    glutSpecialFunc(process_special_keys);
    
    glutMainLoop();

    free(wavDigest);
    free(wavEvent.wavBuf);
    
    hdf5io_close_file(wavFile);
    return EXIT_SUCCESS;
}
