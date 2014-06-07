#include <stdio.h>
#include <stdlib.h>
#include <hdf5.h>
#include "common.h"
#include "hdf5rawWaveformIo.h"

struct HDF5IO(waveform_file) *HDF5IO(open_file)(const char *fname,
                                                size_t nWfmPerChunk,
                                                size_t nCh)
{
    hid_t rootGid, attrSid, attrAid;
    herr_t ret;

    struct HDF5IO(waveform_file) *wavFile;
    wavFile = (struct HDF5IO(waveform_file) *)
        malloc(sizeof(struct HDF5IO(waveform_file)));
    wavFile->waveFid = H5Fcreate(fname, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
    wavFile->nWfmPerChunk = nWfmPerChunk;
    wavFile->nCh = nCh;

    rootGid = H5Gopen(wavFile->waveFid, "/", H5P_DEFAULT);

    wavFile->nEvents = 0; /* an initial value */
    attrSid = H5Screate(H5S_SCALAR);
    attrAid = H5Acreate(rootGid, "nEvents", H5T_NATIVE_HSIZE, attrSid,
                        H5P_DEFAULT, H5P_DEFAULT);
    ret = H5Awrite(attrAid, H5T_NATIVE_HSIZE, &(wavFile->nEvents));
    H5Sclose(attrSid);
    H5Aclose(attrAid);
    attrSid = H5Screate(H5S_SCALAR);
    attrAid = H5Acreate(rootGid, "nWfmPerChunk", H5T_NATIVE_HSIZE, attrSid,
                        H5P_DEFAULT, H5P_DEFAULT);
    ret = H5Awrite(attrAid, H5T_NATIVE_HSIZE, &nWfmPerChunk);
    H5Sclose(attrSid);
    H5Aclose(attrAid);
    attrSid = H5Screate(H5S_SCALAR);
    attrAid = H5Acreate(rootGid, "nCh", H5T_NATIVE_HSIZE, attrSid,
                        H5P_DEFAULT, H5P_DEFAULT);
    ret = H5Awrite(attrAid, H5T_NATIVE_HSIZE, &nCh);
    H5Sclose(attrSid);
    H5Aclose(attrAid);
    H5Gclose(rootGid);

    wavFile->nPt = SCOPE_MEM_LENGTH_MAX;
    return wavFile;
}

struct HDF5IO(waveform_file) *HDF5IO(open_file_for_read)(const char *fname)
{
    hid_t attrAid;
    herr_t ret;

    struct HDF5IO(waveform_file) *wavFile;
    wavFile = (struct HDF5IO(waveform_file) *)
        malloc(sizeof(struct HDF5IO(waveform_file)));
    wavFile->waveFid = H5Fopen(fname, H5F_ACC_RDONLY, H5P_DEFAULT);

    attrAid = H5Aopen_by_name(wavFile->waveFid, "/", "nEvents",
                              H5P_DEFAULT, H5P_DEFAULT);
    ret = H5Aread(attrAid, H5T_NATIVE_HSIZE, &(wavFile->nEvents));
    H5Aclose(attrAid);
    attrAid = H5Aopen_by_name(wavFile->waveFid, "/", "nWfmPerChunk",
                              H5P_DEFAULT, H5P_DEFAULT);
    ret = H5Aread(attrAid, H5T_NATIVE_HSIZE, &(wavFile->nWfmPerChunk));
    H5Aclose(attrAid);
    attrAid = H5Aopen_by_name(wavFile->waveFid, "/", "nCh",
                              H5P_DEFAULT, H5P_DEFAULT);
    ret = H5Aread(attrAid, H5T_NATIVE_HSIZE, &(wavFile->nCh));
    H5Aclose(attrAid);

    wavFile->nPt = SCOPE_MEM_LENGTH_MAX;
    return wavFile;
}

int HDF5IO(close_file)(struct HDF5IO(waveform_file) *wavFile)
{
    herr_t ret;

    ret = H5Fclose(wavFile->waveFid);
    free(wavFile);
    return (int)ret;
}

int HDF5IO(flush_file)(struct HDF5IO(waveform_file) *wavFile)
{
    hid_t attrAid;
    herr_t ret;

    attrAid = H5Aopen_by_name(wavFile->waveFid, "/", "nEvents",
                              H5P_DEFAULT, H5P_DEFAULT);
    ret = H5Awrite(attrAid, H5T_NATIVE_HSIZE, &(wavFile->nEvents));
    H5Aclose(attrAid);
    
    ret = H5Fflush(wavFile->waveFid, H5F_SCOPE_GLOBAL);
    return (int)ret;
}

int HDF5IO(write_waveform_attribute_in_file_header)(
    struct HDF5IO(waveform_file) *wavFile,
    struct waveform_attribute *wavAttr)
{
    herr_t ret;
    
    hid_t wavAttrTid, wavAttrSid, wavAttrAid, doubleArrayTid, rootGid;
    const hsize_t doubleArrayDims[1]={SCOPE_NCH};
    const unsigned doubleArrayRank = 1;

    doubleArrayTid = H5Tarray_create(H5T_NATIVE_DOUBLE, doubleArrayRank, doubleArrayDims);
    
    wavAttrTid = H5Tcreate(H5T_COMPOUND, sizeof(struct waveform_attribute));

    H5Tinsert(wavAttrTid, "wavAttr.chMask", HOFFSET(struct waveform_attribute, chMask),
              H5T_NATIVE_UINT);
    H5Tinsert(wavAttrTid, "wavAttr.nPt", HOFFSET(struct waveform_attribute, nPt),
              H5T_NATIVE_HSIZE);
    H5Tinsert(wavAttrTid, "wavAttr.nFrames", HOFFSET(struct waveform_attribute, nFrames),
              H5T_NATIVE_HSIZE);
    H5Tinsert(wavAttrTid, "wavAttr.dt", HOFFSET(struct waveform_attribute, dt), H5T_NATIVE_DOUBLE);
    H5Tinsert(wavAttrTid, "wavAttr.t0", HOFFSET(struct waveform_attribute, t0), H5T_NATIVE_DOUBLE);
    H5Tinsert(wavAttrTid, "wavAttr.ymult",
              HOFFSET(struct waveform_attribute, ymult), doubleArrayTid);
    H5Tinsert(wavAttrTid, "wavAttr.yoff",
              HOFFSET(struct waveform_attribute, yoff), doubleArrayTid);
    H5Tinsert(wavAttrTid, "wavAttr.yzero",
              HOFFSET(struct waveform_attribute, yzero), doubleArrayTid);

    wavAttrSid = H5Screate(H5S_SCALAR);

    rootGid = H5Gopen(wavFile->waveFid, "/", H5P_DEFAULT);

    wavAttrAid = H5Acreate(rootGid, "Waveform Attributes", wavAttrTid, wavAttrSid,
                           H5P_DEFAULT, H5P_DEFAULT);

    ret = H5Awrite(wavAttrAid, wavAttrTid, wavAttr);

    H5Aclose(wavAttrAid);
    H5Sclose(wavAttrSid);
    H5Tclose(wavAttrTid);
    H5Tclose(doubleArrayTid);
    H5Gclose(rootGid);

    wavFile->nPt = wavAttr->nPt;
    return (int)ret;
}

int HDF5IO(read_waveform_attribute_in_file_header)(
    struct HDF5IO(waveform_file) *wavFile,
    struct waveform_attribute *wavAttr)
{
    herr_t ret;

    hid_t wavAttrTid, wavAttrAid, doubleArrayTid;
    const hsize_t doubleArrayDims[1]={SCOPE_NCH};
    const unsigned doubleArrayRank = 1;

    doubleArrayTid = H5Tarray_create(H5T_NATIVE_DOUBLE, doubleArrayRank, doubleArrayDims);
    
    wavAttrTid = H5Tcreate(H5T_COMPOUND, sizeof(struct waveform_attribute));

    H5Tinsert(wavAttrTid, "wavAttr.chMask", HOFFSET(struct waveform_attribute, chMask),
              H5T_NATIVE_UINT);
    H5Tinsert(wavAttrTid, "wavAttr.nPt", HOFFSET(struct waveform_attribute, nPt),
              H5T_NATIVE_HSIZE);
    H5Tinsert(wavAttrTid, "wavAttr.nFrames", HOFFSET(struct waveform_attribute, nFrames),
              H5T_NATIVE_HSIZE);
    H5Tinsert(wavAttrTid, "wavAttr.dt", HOFFSET(struct waveform_attribute, dt), H5T_NATIVE_DOUBLE);
    H5Tinsert(wavAttrTid, "wavAttr.t0", HOFFSET(struct waveform_attribute, t0), H5T_NATIVE_DOUBLE);
    H5Tinsert(wavAttrTid, "wavAttr.ymult",
              HOFFSET(struct waveform_attribute, ymult), doubleArrayTid);
    H5Tinsert(wavAttrTid, "wavAttr.yoff",
              HOFFSET(struct waveform_attribute, yoff), doubleArrayTid);
    H5Tinsert(wavAttrTid, "wavAttr.yzero",
              HOFFSET(struct waveform_attribute, yzero), doubleArrayTid);

    wavAttrAid = H5Aopen_by_name(wavFile->waveFid, "/", "Waveform Attributes",
                                 H5P_DEFAULT, H5P_DEFAULT);
    ret = H5Aread(wavAttrAid, wavAttrTid, wavAttr);

    H5Aclose(wavAttrAid);
    H5Tclose(wavAttrTid);
    H5Tclose(doubleArrayTid);

    wavFile->nPt = wavAttr->nPt;
    return (int)ret;
}

int HDF5IO(write_event)(struct HDF5IO(waveform_file) *wavFile,
                        struct HDF5IO(waveform_event) *wavEvent)
{
    char buf[NAME_BUF_SIZE];
    herr_t ret;
    size_t chunkId, inChunkId;
    hid_t rootGid, chSid, chPid, chTid, chDid;
    hid_t mSid;
    hsize_t dims[2], h5chunkDims[2], slabOff[2], mOff[2], slabDims[2];
    
    chunkId = wavEvent->eventId / wavFile->nWfmPerChunk;
    inChunkId = wavEvent->eventId % wavFile->nWfmPerChunk;

    snprintf(buf, NAME_BUF_SIZE, "C%zd", chunkId);
    rootGid = H5Gopen(wavFile->waveFid, "/", H5P_DEFAULT);

#define write_event_create_dataset                   \
    do {                                                    \
        dims[0] = wavFile->nCh;                             \
        dims[1] = wavFile->nPt * wavFile->nWfmPerChunk;     \
        h5chunkDims[0] = 1;                                 \
        h5chunkDims[1] = wavFile->nPt;                      \
                                                            \
        chSid = H5Screate_simple(2, dims, NULL);            \
        chPid = H5Pcreate(H5P_DATASET_CREATE);              \
        H5Pset_chunk(chPid, 2, h5chunkDims);                \
        /* H5Pset_deflate(chPid, 6); */                     \
                                                            \
        chTid = H5Tcopy(SCOPE_DATA_HDF5_TYPE);              \
        chDid = H5Dcreate(rootGid, buf, chTid, chSid,       \
                          H5P_DEFAULT, chPid, H5P_DEFAULT); \
                                                            \
        H5Tclose(chTid);                                    \
        H5Pclose(chPid);                                    \
    } while(0)

    if(inChunkId == 0) { /* need to create a new chunk */
        write_event_create_dataset;
    } else {
        chDid = H5Dopen(rootGid, buf, H5P_DEFAULT);
        if(chDid < 0) { /* need to create a new chunk */
            /* This is not a neat way to do it.  One may check out
             * H5Lexists() and try to utilize that function.  Its
             * efficiency is not verified though. */
            write_event_create_dataset;
        } else {
            chSid = H5Dget_space(chDid);
        }
    }
#undef write_event_create_dataset

    slabOff[0] = 0;
    slabOff[1] = inChunkId * wavFile->nPt;
    slabDims[0] = wavFile->nCh;
    slabDims[1] = wavFile->nPt;
    H5Sselect_hyperslab(chSid, H5S_SELECT_SET, slabOff, NULL, slabDims, NULL);

    mSid = H5Screate_simple(2, slabDims, NULL);
    mOff[0] = 0;
    mOff[1] = 0;
    H5Sselect_hyperslab(mSid, H5S_SELECT_SET, mOff, NULL, slabDims, NULL);
    
    ret = H5Dwrite(chDid, SCOPE_DATA_HDF5_TYPE, mSid, chSid, H5P_DEFAULT,
                   wavEvent->wavBuf);

    wavFile->nEvents++;

    H5Sclose(mSid);
    H5Sclose(chSid);
    H5Dclose(chDid);
    H5Gclose(rootGid);
    return (int)ret;
}

int HDF5IO(read_event)(struct HDF5IO(waveform_file) *wavFile,
                       struct HDF5IO(waveform_event) *wavEvent)
{
    char buf[NAME_BUF_SIZE];
    herr_t ret;
    size_t chunkId, inChunkId;
    hid_t chSid, chDid;
    hid_t mSid;
    hsize_t slabOff[2], mOff[2], slabDims[2];
    
    chunkId = wavEvent->eventId / wavFile->nWfmPerChunk;
    inChunkId = wavEvent->eventId % wavFile->nWfmPerChunk;

    snprintf(buf, NAME_BUF_SIZE, "/C%zd", chunkId);
    chDid = H5Dopen(wavFile->waveFid, buf, H5P_DEFAULT);
    chSid = H5Dget_space(chDid);

    slabOff[0] = 0;
    slabOff[1] = inChunkId * wavFile->nPt;
    slabDims[0] = wavFile->nCh;
    slabDims[1] = wavFile->nPt;
    H5Sselect_hyperslab(chSid, H5S_SELECT_SET, slabOff, NULL, slabDims, NULL);

    mSid = H5Screate_simple(2, slabDims, NULL);
    mOff[0] = 0;
    mOff[1] = 0;
    H5Sselect_hyperslab(mSid, H5S_SELECT_SET, mOff, NULL, slabDims, NULL);

    ret = H5Dread(chDid, SCOPE_DATA_HDF5_TYPE, mSid, chSid, H5P_DEFAULT,
                  wavEvent->wavBuf);

    H5Sclose(mSid);
    H5Sclose(chSid);
    H5Dclose(chDid);
    return (int)ret;
}

size_t HDF5IO(get_number_of_events)(struct HDF5IO(waveform_file) *wavFile)
{
    /*
    herr_t ret;
    hid_t rootGid;
    H5G_info_t rootGinfo;
    size_t nEvents;
    
    rootGid = H5Gopen(wavFile->waveFid, "/", H5P_DEFAULT);
    ret = H5Gget_info(rootGid, &rootGinfo);
    nEvents = rootGinfo.nlinks;

    H5Gclose(rootGid);
    return nEvents;
    */
    return wavFile->nEvents;
}

#ifdef HDF5IO_DEBUG_ENABLEMAIN
int main(int argc, char **argv)
{
    int i;
    SCOPE_DATA_TYPE array[20000]={1,2,3,4,5,
                                  6,7,8,9,10,
                                  11,12,13,14,15,
                                  16,17,18,19,20};

    struct HDF5IO(waveform_file) *wavFile;
    struct waveform_attribute wavAttr = {
        .chMask = 0x0a,
        .nPt = 10000,
        .dt = 1e-6,
        .t0 = 0.0,
        .ymult = {1,1,1,1},
        .yoff = {0,0,0,0},
        .yzero = {0,0,0,0}
    };

    struct HDF5IO(waveform_event) evt = {
        .eventId = 0,
        .wavBuf = (SCOPE_DATA_TYPE*)array
    };

    wavFile = HDF5IO(open_file)("test.h5", 4, 2);
    printf("wavFile->nWfmPerChunk = %zd\n", wavFile->nWfmPerChunk);
    printf("wavFile->nCh = %zd\n", wavFile->nCh);
    printf("wavFile->nPt = %zd\n", wavFile->nPt);
    HDF5IO(write_waveform_attribute_in_file_header)(wavFile, &wavAttr);
    printf("wavFile->nPt = %zd\n", wavFile->nPt);

    HDF5IO(write_event)(wavFile, &evt);
    evt.eventId = 1;
    HDF5IO(write_event)(wavFile, &evt);
    evt.eventId = 4;
    HDF5IO(write_event)(wavFile, &evt);
    evt.eventId = 8;
    HDF5IO(write_event)(wavFile, &evt);
    evt.eventId = 9;
    HDF5IO(write_event)(wavFile, &evt);

    HDF5IO(flush_file)(wavFile);
    HDF5IO(close_file)(wavFile);

    wavFile = HDF5IO(open_file_for_read)("test.h5");
    printf("number of events: %zd\n", HDF5IO(get_number_of_events)(wavFile));
    printf("wavFile->nWfmPerChunk = %zd\n", wavFile->nWfmPerChunk);
    printf("wavFile->nCh = %zd\n", wavFile->nCh);
    printf("wavFile->nPt = %zd\n", wavFile->nPt);
    HDF5IO(read_waveform_attribute_in_file_header)(wavFile, &wavAttr);
    printf("wavFile->nPt = %zd\n", wavFile->nPt);
    printf("number of events: %zd\n", HDF5IO(get_number_of_events)(wavFile));
    printf("%zd, %g, %g\n", wavAttr.nPt, wavAttr.dt, wavAttr.t0);

    for(i=0; i < wavFile->nCh * wavFile->nPt; i++) {
        evt.wavBuf[i] = 0;
    }
    evt.eventId = 1;
    HDF5IO(read_event)(wavFile, &evt);
    for(i=0; i < wavFile->nCh * wavFile->nPt; i++) {
        printf("%d ", evt.wavBuf[i]);
    }
    printf("\n");
    
    HDF5IO(close_file)(wavFile);
    
    return EXIT_SUCCESS;
}
#endif
