# NGINX-based Media Streaming Server
## nginx-rtmp-module


### Project blog

  http://nginx-rtmp.blogspot.com

### Wiki manual

  https://github.com/arut/nginx-rtmp-module/wiki/Directives

### Google group

  https://groups.google.com/group/nginx-rtmp

  https://groups.google.com/group/nginx-rtmp-ru (Russian)

### Donation page (Paypal etc)

  http://arut.github.com/nginx-rtmp-module/

### Features

* RTMP/HLS/MPEG-DASH live streaming

* RTMP Video on demand FLV/MP4,
  playing from local filesystem or HTTP

* Stream relay support for distributed
  streaming: push & pull models

* Recording streams in multiple FLVs

* H264/AAC, HEVC (H.265), AV1, VP9 and Opus support (Enhanced RTMP)

* Online transcoding with FFmpeg

* HTTP callbacks (publish/play/record/update etc)

* Running external programs on certain events (exec)

* HTTP control module for recording audio/video and dropping clients

* Advanced buffering techniques
  to keep memory allocations at a minimum
  level for faster streaming and low
  memory footprint

* Proved to work with Wirecast, FMS, Wowza,
  JWPlayer, FlowPlayer, StrobeMediaPlayback,
  ffmpeg, avconv, rtmpdump, flvstreamer
  and many more

* Statistics in XML/XSL in machine- & human-
  readable form

* Linux/FreeBSD/MacOS/Windows

### Build

cd to NGINX source directory & run this:

    ./configure --add-module=/path/to/nginx-rtmp-module
    make
    make install

Several versions of nginx (1.3.14 - 1.5.0) require http_ssl_module to be
added as well:

    ./configure --add-module=/path/to/nginx-rtmp-module --with-http_ssl_module

For building debug version of nginx add `--with-debug`

    ./configure --add-module=/path/to-nginx/rtmp-module --with-debug

[Read more about debug log](https://github.com/arut/nginx-rtmp-module/wiki/Debug-log)

### Windows limitations

Windows support is limited. These features are not supported

* execs
* static pulls
* auto_push

### RTMP URL format

    rtmp://rtmp.example.com/app[/name]

app -  should match one of application {}
         blocks in config

name - interpreted by each application
         can be empty


### Multi-worker live streaming

Module supports multi-worker live
streaming through automatic stream pushing
to nginx workers. This option is toggled with
rtmp_auto_push directive.


### Example nginx.conf

    rtmp {

        server {

            listen 1935;

            chunk_size 4000;

            # TV mode: one publisher, many subscribers
            application mytv {

                # enable live streaming
                live on;

                # record first 1K of stream
                record all;
                record_path /tmp/av;
                record_max_size 1K;

                # append current timestamp to each flv
                record_unique on;

                # publish only from localhost
                allow publish 127.0.0.1;
                deny publish all;

                #allow play all;
            }

            # Transcoding (ffmpeg needed)
            application big {
                live on;

                # On every pusblished stream run this command (ffmpeg)
                # with substitutions: $app/${app}, $name/${name} for application & stream name.
                #
                # This ffmpeg call receives stream from this application &
                # reduces the resolution down to 32x32. The stream is the published to
                # 'small' application (see below) under the same name.
                #
                # ffmpeg can do anything with the stream like video/audio
                # transcoding, resizing, altering container/codec params etc
                #
                # Multiple exec lines can be specified.

                exec ffmpeg -re -i rtmp://localhost:1935/$app/$name -vcodec flv -acodec copy -s 32x32
                            -f flv rtmp://localhost:1935/small/${name};
            }

            application small {
                live on;
                # Video with reduced resolution comes here from ffmpeg
            }

            application webcam {
                live on;

                # Stream from local webcam
                exec_static ffmpeg -f video4linux2 -i /dev/video0 -c:v libx264 -an
                                   -f flv rtmp://localhost:1935/webcam/mystream;
            }

            application mypush {
                live on;

                # Every stream published here
                # is automatically pushed to
                # these two machines
                push rtmp1.example.com;
                push rtmp2.example.com:1934;
            }

            application mypull {
                live on;

                # Pull all streams from remote machine
                # and play locally
                pull rtmp://rtmp3.example.com pageUrl=www.example.com/index.html;
            }

            application mystaticpull {
                live on;

                # Static pull is started at nginx start
                pull rtmp://rtmp4.example.com pageUrl=www.example.com/index.html name=mystream static;
            }

            # video on demand
            application vod {
                play /var/flvs;
            }

            application vod2 {
                play /var/mp4s;
            }

            # Many publishers, many subscribers
            # no checks, no recording
            application videochat {

                live on;

                # The following notifications receive all
                # the session variables as well as
                # particular call arguments in HTTP POST
                # request

                # Make HTTP request & use HTTP retcode
                # to decide whether to allow publishing
                # from this connection or not
                on_publish http://localhost:8080/publish;

                # Same with playing
                on_play http://localhost:8080/play;

                # Publish/play end (repeats on disconnect)
                on_done http://localhost:8080/done;

                # All above mentioned notifications receive
                # standard connect() arguments as well as
                # play/publish ones. If any arguments are sent
                # with GET-style syntax to play & publish
                # these are also included.
                # Example URL:
                #   rtmp://localhost/myapp/mystream?a=b&c=d

                # record 10 video keyframes (no audio) every 2 minutes
                record keyframes;
                record_path /tmp/vc;
                record_max_frames 10;
                record_interval 2m;

                # Async notify about an flv recorded
                on_record_done http://localhost:8080/record_done;

            }


            # HLS

            # For HLS to work please create a directory in tmpfs (/tmp/hls here)
            # for the fragments. The directory contents is served via HTTP (see
            # http{} section in config)
            #
            # Incoming stream must be in H264/AAC. For iPhones use baseline H264
            # profile (see ffmpeg example).
            # This example creates RTMP stream from movie ready for HLS:
            #
            # ffmpeg -loglevel verbose -re -i movie.avi  -vcodec libx264
            #    -vprofile baseline -acodec libmp3lame -ar 44100 -ac 1
            #    -f flv rtmp://localhost:1935/hls/movie
            #
            # If you need to transcode live stream use 'exec' feature.
            #
            application hls {
                live on;
                hls on;
                hls_path /tmp/hls;
            }

            # MPEG-DASH is similar to HLS

            application dash {
                live on;
                dash on;
                dash_path /tmp/dash;
            }
        }
    }

### Security and Compatibility Updates (2026)

This module has been updated and audited for modern security standards and compatibility:

* **USN-7285-1 (LP#1977718) Verified**: Confirmed that critical fixes for buffer overflow in `ngx_rtmp_handler.c` and null pointer dereference in `ngx_rtmp_amf.c` are present.
* **Memory Safety Fix**: Resolved a memory leak in `ngx_rtmp_eval.c` by ensuring old buffers are freed during string evaluation resizing.
* **Hardening**: Eliminated Variable Length Arrays (VLAs) in `ngx_rtmp_amf.c` to protect against stack exhaustion, replacing them with safe fixed-size buffers and boundary checks.
* **Enhanced Randomness**: Replaced legacy `rand()` with the cryptographically more secure `ngx_random()` in the handshake implementation.
* **Nginx 1.30.1 Compatibility**: Updated and verified the module for compatibility with Nginx version 1.30.1.
* **Enhanced RTMP Support**: Integrated support for modern codecs including HEVC (H.265), AV1, VP9, and Opus, following the Enhanced RTMP specification. Includes detailed parsing for HEVC sequence headers.
* **Nvidia Codec Integration**: Added support for additional FourCCs (e.g., `hev1`) used by Nvidia NVENC encoders.
* **Vertical Video Support**: Added metadata handling for `rotation` to support vertical video orientation.
* **Compatibility & Future-proofing**: Fully validated against Nginx 1.30.1 and 1.30.2, ensuring stable operation with the latest mainline and stable branches.
* **Note on RTMPS**: For RTMPS support, Nginx SSL termination (via the stream module) is the recommended and most stable approach for certificate management and auto-renewal.

    # HTTP can be used for accessing RTMP stats
    http {

        server {

            listen      8080;

            # This URL provides RTMP statistics in XML
            location /stat {
                rtmp_stat all;

                # Use this stylesheet to view XML as web page
                # in browser
                rtmp_stat_stylesheet stat.xsl;
            }

            location /stat.xsl {
                # XML stylesheet to view RTMP stats.
                # Copy stat.xsl wherever you want
                # and put the full directory path here
                root /path/to/stat.xsl/;
            }

            location /hls {
                # Serve HLS fragments
                types {
                    application/vnd.apple.mpegurl m3u8;
                    video/mp2t ts;
                }
                root /tmp;
                add_header Cache-Control no-cache;
            }

            location /dash {
                # Serve DASH fragments
                root /tmp;
                add_header Cache-Control no-cache;
            }
        }
    }


### Multi-worker streaming example

    rtmp_auto_push on;

    rtmp {
        server {
            listen 1935;

            application mytv {
                live on;
            }
        }
    }
