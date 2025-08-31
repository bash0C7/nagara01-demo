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
$active_notes = []
$arpeggio_pos = 0

puts "MIDI LED Visualizer Starting..."
sleep_ms(1000)
byte1 = 0xC0.chr
byte2 = 83.chr  
program_change = byte1 + byte2
$midi_uart.write(program_change)
sleep_ms(100)
puts "Ready!"

def get_color(note, velocity)
  semitone = note % 12
  brightness = velocity * 2
  if brightness > 255
    brightness = 255
  end
  
  r = 0
  g = 0
  b = 0
  
  case semitone
  when 0
    r = brightness
  when 1
    r = brightness
    g = brightness / 4
  when 2
    r = brightness
    g = brightness / 2
  when 3
    r = brightness
    g = brightness * 3 / 4
  when 4
    r = brightness
    g = brightness
  when 5
    r = brightness / 2
    g = brightness
  when 6
    g = brightness
  when 7
    g = brightness
    b = brightness / 2
  when 8
    g = brightness
    b = brightness
  when 9
    g = brightness / 2
    b = brightness
  when 10
    b = brightness
  when 11
    r = brightness / 2
    b = brightness
  end
  
  return (r << 16) | (g << 8) | b
end

def add_note(note, velocity)
  found = false
  i = 0
  while i < $active_notes.length
    if $active_notes[i] == note
      found = true
      break
    end
    i += 1
  end
  
  if !found
    $active_notes.push(note)
    puts "Note ON: #{note} (#{$active_notes.length} active)"
  end
end

def remove_note(note)
  i = 0
  while i < $active_notes.length
    if $active_notes[i] == note
      $active_notes.delete_at(i)
      puts "Note OFF: #{note} (#{$active_notes.length} active)"
      break
    end
    i += 1
  end
end

def update_display
  i = 0
  while i < 60
    $colors[i] = 0
    i += 1
  end
  
  if $active_notes.length > 0
    i = 0
    while i < $active_notes.length
      note = $active_notes[i]
      color = get_color(note, 120)
      
      pos = ($arpeggio_pos + i * 20) % 60
      $colors[pos] = color
      
      if pos > 0
        $colors[pos - 1] = color / 3
      end
      if pos < 59
        $colors[pos + 1] = color / 3
      end
      
      i += 1
    end
    
    $arpeggio_pos = ($arpeggio_pos + 2) % 60
  else
    pos = $arpeggio_pos % 60
    $colors[pos] = 0x001100
    $arpeggio_pos = ($arpeggio_pos + 1) % 60
  end
end

loop_count = 0

loop do
  loop_count += 1
  
  data = $pc_uart.read
  
  if data && data.length > 0
    $midi_uart.write(data)
    
    if loop_count <= 5
      puts "MIDI Data: #{data.bytes.map{|b| sprintf('%02X', b)}.join(' ')}"
    end
    
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
          add_note($note_byte, byte)
        elsif $status_byte == 0x80 || ($status_byte == 0x90 && byte == 0)
          remove_note($note_byte)
        end
        $midi_state = 0
      end
      
      byte_index += 1
    end
  end
  
  update_display
  $led.show_hex(*$colors)
  sleep_ms(30)
end
