#!/bin/bash

sudo pacman --noconfirm -S firefox-developer-edition

#
# Add to picom
sed -i -E \
"/\b(firefox|firefoxdeveloperedition)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(shadow-exclude\s*=\s*\[):\1\n  \"class_g ~= 'firefox' \&\& window_type \*= 'utility'\",:g; \
s:^\s*(shadow-exclude\s*=\s*\[):\1\n  \"class_g ~= 'firefox' \&\& window_type \*= 'tooltip'\",:g; \
s:^\s*(shadow-exclude\s*=\s*\[):\1\n  \"class_g ~= 'firefox' \&\& window_type \*= 'menu'\",:g; \
s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g = 'firefox' \&\& focused\",:g; \
s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g = 'firefoxdeveloperedition' \&\& focused\",:g" \
$V_HOME/.config/picom/picom.conf

#
# Override default about:config
sudo bash -c "cat > /usr/lib/firefox-developer-edition/defaults/pref/local-settings.js" << EOL
pref("general.config.obscure_value", 0);
pref("general.config.filename", "mozilla.cfg");
EOL

sudo bash -c "cat > /usr/lib/firefox-developer-edition/mozilla.cfg" << EOL
// Disable timeout warning
defaultPref("full-screen-api.warning.timeout", 0);
// Disable fingerprint memory
//defaultPref("privacy.resistFingerprinting", true);
// Enable touch screen
defaultPref("dom.w3c_touch_events.enabled", 1);
EOL

#
# Enable XINPUT2
if [ -n "$S_ADD_FF_XINPUT" ]; then
  echo "MOZ_USE_XINPUT2 DEFAULT=1" | sudo tee -a /etc/security/pam_env.conf
  sudo bash -c "cat >> /usr/lib/firefox-developer-edition/mozilla.cfg" << EOL
// Enable touch screen
defaultPref("dom.w3c_touch_events.enabled", 1);
EOL
fi

#
# Preconfig for hardware accel
if [ -n "$S_ADD_FF_VAAPI" ]; then
  sudo bash -c "cat >> /usr/lib/firefox-developer-edition/mozilla.cfg" << EOL
// enable the use of VA-API with FFmpeg
defaultPref("media.ffmpeg.vaapi.enabled", true);
// disable the internal decoders for VP8/VP9
defaultPref("media.ffvpx.enabled", false);
// disable the remote data decoder process for VP8/VP9
defaultPref("media.rdd-vpx.enabled", false);
// enable hardware VA-API decoding for WebRTC
defaultPref("media.navigator.mediadatadecoder_vpx_enabled", true);
// run Firefox with the following environment variable
defaultPref("gfx.x11-egl.force-enabled", true);
// run Firefox with the following environment variable
defaultPref("gfx.x11-egl.force-disabled", false);
// Enable WebRender
defaultPref("gfx.webrender.all", true);
EOL
fi
