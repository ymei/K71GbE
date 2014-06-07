#ifndef __HDF5IO_H__
#define __HDF5IO_H__

#include <hdf5.h>

#define NAME_BUF_SIZE 256

struct HDF5IO(waveform_file)
{
    hid_t waveFid;
    size_t nPt;
    size_t nCh;
    size_t nWfmPerChunk;
    size_t nEvents;
};

struct HDF5IO(waveform_event)
{
    size_t eventId;
    /* wavBuf should point to a contiguous 2D array, mapped as
     * ch1..ch2..ch3..ch4 (row-major).  Omitting one or more ch? is
     * allowed in accordance with chMask.*/
    SCOPE_DATA_TYPE *wavBuf;
};

/* nWfmPerChunk: waveforms are stored in 2D arrays.  To optimize
 * performance, n waveforms are grouped together to be put in the same
 * array, then the (n+1)th waveform is put into the next grouped
 * array, and so forth. */
struct HDF5IO(waveform_file) *HDF5IO(open_file)(
    const char *fname, size_t nWfmPerChunk,
    size_t nCh);
struct HDF5IO(waveform_file) *HDF5IO(open_file_for_read)(const char *fname);
int HDF5IO(close_file)(struct HDF5IO(waveform_file) *wavFile);
/* flush also writes nEvents to the file */
int HDF5IO(flush_file)(struct HDF5IO(waveform_file) *wavFile);

int HDF5IO(write_waveform_attribute_in_file_header)(
    struct HDF5IO(waveform_file) *wavFile,
    struct waveform_attribute *wavAttr);
int HDF5IO(read_waveform_attribute_in_file_header)(
    struct HDF5IO(waveform_file) *wavFile,
    struct waveform_attribute *wavAttr);
int HDF5IO(write_event)(struct HDF5IO(waveform_file) *wavFile,
                        struct HDF5IO(waveform_event) *wavEvent);
int HDF5IO(read_event)(struct HDF5IO(waveform_file) *wavFile,
                       struct HDF5IO(waveform_event) *wavEvent);
size_t HDF5IO(get_number_of_events)(struct HDF5IO(waveform_file) *wavFile);

#endif /* __HDF5IO_H__ */
