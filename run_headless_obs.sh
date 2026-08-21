#!/bin/bash
# run_headless_obs.sh
# Run Xvfb with a resolution large enough for both 1920x1080 and 1080x1920
# (e.g., 3840x2160 ensures both canvases have enough room to render without crashing the encoder)

if pgrep -x "Xvfb" > /dev/null; then
    echo "Xvfb is already running."
else
    Xvfb :99 -screen 0 3840x2160x24 &
    sleep 2
fi

export DISPLAY=:99
echo "Starting OBS Studio headlessly on virtual display :99..."
obs-studio &
