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
$active_notes = {}
$arpeggio_pos = 0

sleep_ms(1000)
byte1 = 0xC0.chr
byte2 = 83.chr  
program_change = byte1 + byte2
$midi_uart.write(program_change)
sleep_ms(100)

def get_spectrum_color(note, velocity)
  semitone = note % 12
  brightness = velocity < 127 ? velocity * 2 : 254
  
  case semitone
  when 0; [brightness, 0, 0]
  when 1; [brightness, brightness >> 2, 0]
  when 2; [brightness, brightness >> 1, 0]
  when 3; [brightness, (brightness * 3) >> 2, 0]
  when 4; [brightness, brightness, 0]
  when 5; [brightness >> 1, brightness, 0]
  when 6; [0, brightness, 0]
  when 7; [0, brightness, brightness >> 1]
  when 8; [0, brightness, brightness]
  when 9; [0, brightness >> 1, brightness]
  when 10; [0, 0, brightness]
  when 11; [brightness >> 1, 0, brightness]
  end
end

def update_light(note, velocity, is_note_on)
  if is_note_on
    $active_notes[note] = velocity
  else
    $active_notes.delete(note)
  end
end

def update_arpeggio_display
  i = 0
  while i < 60
    $colors[i] = 0
    i += 1
  end
  
  return if $active_notes.empty?
  
  $active_notes.each_with_index do |(note, velocity), idx|
    color = get_spectrum_color(note, velocity)
    phase_offset = idx * 15
    wave_pos = ($arpeggio_pos + phase_offset) % 60
    
    led_pos = wave_pos
    return if led_pos < 0 || led_pos >= 60
    
    r = color[0]
    g = color[1] 
    b = color[2]
    
    $colors[led_pos] = (r << 16) | (g << 8) | b
    
    if led_pos > 0
      r2 = r >> 2
      g2 = g >> 2
      b2 = b >> 2
      $colors[led_pos - 1] = (r2 << 16) | (g2 << 8) | b2
    end
    
    if led_pos < 59
      r3 = r >> 2
      g3 = g >> 2
      b3 = b >> 2
      $colors[led_pos + 1] = (r3 << 16) | (g3 << 8) | b3
    end
  end
  
  $arpeggio_pos = ($arpeggio_pos + 1) % 60
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
        if $status_byte == 0x90 && byte > 0
          update_light($note_byte, byte, true)
        elsif $status_byte == 0x80 || ($status_byte == 0x90 && byte == 0)
          update_light($note_byte, 0, false)
        end
        $midi_state = 0
      end
      
      byte_index += 1
    end
  end
  
  update_arpeggio_display
  $led.show_hex(*$colors)
  sleep_ms(30)
end
