# MIDIシンセサイザーデモ - PC→LEDビジュアライザー
# 外付け60 LED(J5ポートGPIO 22) + MIDI入出力(USB,GPIO 23/33)
require 'uart'
require 'ws2812'

$pc_uart = UART.new(unit: :ESP32_UART0, baudrate: 115200)
$midi_uart = UART.new(unit: :ESP32_UART1, baudrate: 31250, txd_pin: 23, rxd_pin: 33)
$led = WS2812.new(RMTDriver.new(22))
$colors = Array.new(60, 0)
$midi_state = 0
$status_byte = 0
$note_byte = 0

sleep_ms(1000)
byte1 = 0xC0.chr
byte2 = 83.chr  
program_change = byte1 + byte2
$midi_uart.write(program_change)
sleep_ms(100)

def update_light(note, velocity, is_note_on)
  return if note < 36 || note > 84
  
  semitone = (note - 36) % 12
  octave = (note - 36) / 12
  pos = semitone * 5 + octave
  return if pos < 0 || pos >= 60
  
  if is_note_on
    brightness = velocity * 2
    brightness = 255 if brightness > 255
    
    case semitone
    when 0
      r, g, b = brightness, 0, 0
    when 1
      r, g, b = brightness, brightness/4, 0
    when 2
      r, g, b = brightness, brightness/2, 0
    when 3
      r, g, b = brightness, brightness*3/4, 0
    when 4
      r, g, b = brightness, brightness, 0
    when 5
      r, g, b = brightness/2, brightness, 0
    when 6
      r, g, b = 0, brightness, 0
    when 7
      r, g, b = 0, brightness, brightness/2
    when 8
      r, g, b = 0, brightness, brightness
    when 9
      r, g, b = 0, brightness/2, brightness
    when 10
      r, g, b = 0, 0, brightness
    when 11
      r, g, b = brightness/2, 0, brightness
    end
    
    color = (r << 16) | (g << 8) | b
    $colors[pos] = color
    
    if pos > 0
      $colors[pos - 1] = color * 2 / 3
    end
    if pos < 59
      $colors[pos + 1] = color * 2 / 3
    end
    if pos > 1
      $colors[pos - 2] = color / 3
    end
    if pos < 58
      $colors[pos + 2] = color / 3
    end
  else
    $colors[pos] = 0
    if pos > 0
      $colors[pos - 1] = 0
    end
    if pos < 59
      $colors[pos + 1] = 0
    end
    if pos > 1
      $colors[pos - 2] = 0
    end
    if pos < 58
      $colors[pos + 2] = 0
    end
  end
end

def fade_lights
  i = 0
  while i < 60
    $colors[i] = $colors[i] * 97 / 100 if $colors[i] > 5
    $colors[i] = 0 if $colors[i] <= 5
    i += 1
  end
end

def build_rgb_array
  rgb_array = []
  i = 0
  while i < 60
    c = $colors[i]
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF
    rgb_array.push(r)
    rgb_array.push(g)
    rgb_array.push(b)
    i += 1
  end
  rgb_array
end

loop do
  data = $pc_uart.read
  
  if data && data.length > 0
    $midi_uart.write(data)
    
    byte_index = 0
    while byte_index < data.length
      byte = data[byte_index].ord
      
      case $midi_state
      when 0
        if byte == 0x90 || byte == 0x80
          $status_byte = byte
          $midi_state = 1
        end
      when 1
        $note_byte = byte
        $midi_state = 2
      when 2
        if $status_byte == 0x90
          update_light($note_byte, byte, true)
        elsif $status_byte == 0x80
          update_light($note_byte, 0, false)
        end
        $midi_state = 0
      end
      
      byte_index += 1
    end
  end
  
  fade_lights
  $led.show_hex(*$colors)
  sleep_ms(25)
end
