# MIDIシンセサイザーデモ - PC→LEDビジュアライザー
# 外付け60 LED(J5ポートGPIO 22) + MIDI入出力(USB,GPIO 23/33)
require 'uart'
require 'ws2812'

puts "1. ライブラリ読み込み完了"

$pc_uart = UART.new(unit: :ESP32_UART0, baudrate: 115200)
puts "2. PC_UART初期化完了"

$midi_uart = UART.new(unit: :ESP32_UART1, baudrate: 31250, txd_pin: 23, rxd_pin: 33)
puts "3. MIDI_UART初期化完了"

$led = WS2812.new(RMTDriver.new(22))
puts "4. LED初期化完了"

$colors = Array.new(60, 0)
puts "5. カラー配列初期化完了"

$midi_state = 0
$status_byte = 0
$note_byte = 0
$active_notes = {}  # 現在鳴っている音程と開始時刻
$arpeggio_pos = 0   # アルペジオ位置カウンタ
puts "6. グローバル変数初期化完了"

# 音色設定
sleep_ms(1000)
puts "7. スリープ完了"

# 手動で安全にバイト変換
puts "8-1. 手動バイト変換開始"
byte1 = 0xC0.chr
puts "8-2. 1バイト目変換完了"
byte2 = 83.chr  
puts "8-3. 2バイト目変換完了"
program_change = byte1 + byte2
puts "8-4. データ結合完了"
$midi_uart.write(program_change)
puts "8-5. MIDI音色設定送信完了"

sleep_ms(100)
puts "9. 音色設定後スリープ完了"

def get_spectrum_color(note, velocity)
  # 12音階を0-11にマッピング（ドレミファソラシド + 半音）
  semitone = note % 12
  brightness = velocity * 2
  brightness = 255 if brightness > 255
  
  # 12音階をR→G→Bスペクトラムにマッピング
  case semitone
  when 0; [brightness, 0, 0]           # ド: 赤
  when 1; [brightness, brightness/4, 0] # ド#: 赤オレンジ
  when 2; [brightness, brightness/2, 0] # レ: オレンジ
  when 3; [brightness, brightness*3/4, 0] # レ#: 黄オレンジ
  when 4; [brightness, brightness, 0]   # ミ: 黄
  when 5; [brightness/2, brightness, 0] # ファ: 黄緑
  when 6; [0, brightness, 0]           # ファ#: 緑
  when 7; [0, brightness, brightness/2] # ソ: 青緑
  when 8; [0, brightness, brightness]   # ソ#: シアン
  when 9; [0, brightness/2, brightness] # ラ: 青シアン
  when 10; [0, 0, brightness]          # ラ#: 青
  when 11; [brightness/2, 0, brightness] # シ: 青紫
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
  # 全LEDをリセット
  60.times { |i| $colors[i] = 0 }
  
  return if $active_notes.empty?
  
  # アクティブな音程の色を計算
  note_colors = {}
  $active_notes.each do |note, velocity|
    note_colors[note] = get_spectrum_color(note, velocity)
  end
  
  # アルペジオ効果：複数音が鳴っている場合は混合表示
  $active_notes.keys.each_with_index do |note, idx|
    color = note_colors[note]
    
    # アルペジオ位置計算（各音程で位相をずらす）
    phase_offset = idx * 15  # 音程ごとに位相差
    wave_pos = ($arpeggio_pos + phase_offset) % 60
    
    # 波状に3つのLEDを光らせる
    (-1..1).each do |offset|
      led_pos = (wave_pos + offset) % 60
      intensity = offset == 0 ? 1.0 : 0.3  # 中心は明るく、両端は暗く
      
      # 既存の色と加算合成
      r = ($colors[led_pos] >> 16) & 0xFF
      g = ($colors[led_pos] >> 8) & 0xFF  
      b = $colors[led_pos] & 0xFF
      
      r = [r + (color[0] * intensity).to_i, 255].min
      g = [g + (color[1] * intensity).to_i, 255].min
      b = [b + (color[2] * intensity).to_i, 255].min
      
      $colors[led_pos] = (r << 16) | (g << 8) | b
    end
  end
  
  # アルペジオ位置を進める
  $arpeggio_pos = ($arpeggio_pos + 2) % 60
end

puts "10. update_light/arpeggio関数定義完了"

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

puts "11. build_rgb_array関数定義完了"

puts "12. メインループ開始"
loop_count = 0

loop do
  loop_count += 1
  if loop_count % 100 == 0
    puts "ループ#{loop_count}回目実行中"
  end
  
  puts "13. データ読み取り開始" if loop_count == 1
  data = $pc_uart.read
  puts "14. データ読み取り完了" if loop_count == 1
  
  if data && data.length > 0
    puts "★受信データ: 長さ#{data.length} 内容:#{data.bytes.map{|b| sprintf('%02X', b)}.join(' ')}"
    
    puts "15. MIDI転送開始" if loop_count <= 3
    $midi_uart.write(data)
    puts "16. MIDI転送完了" if loop_count <= 3
    
    puts "17. バイト処理開始" if loop_count <= 3
    byte_index = 0
    while byte_index < data.length
      puts "18. バイト#{byte_index}処理中" if loop_count == 1
      
      byte = data[byte_index].ord
      puts "★バイト値: #{sprintf('%02X', byte)} 状態:#{$midi_state}" if loop_count <= 2
      
      case $midi_state
      when 0
        if byte == 0x90 || byte == 0x80
          $status_byte = byte
          $midi_state = 1
          puts "★ステータス受信: #{sprintf('%02X', byte)}" if loop_count <= 2
        end
      when 1
        $note_byte = byte
        $midi_state = 2
        puts "★ノート受信: #{byte}" if loop_count <= 2
      when 2
        if $status_byte == 0x90
          puts "★Note ON: ノート#{$note_byte} ベロシティ#{byte}" if loop_count <= 2
          update_light($note_byte, byte, true)
        elsif $status_byte == 0x80
          puts "★Note OFF: ノート#{$note_byte}" if loop_count <= 2
          update_light($note_byte, 0, false)
        end
        $midi_state = 0
      end
      
      byte_index += 1
    end
    puts "19. バイト処理完了" if loop_count <= 3
  end
  
  puts "20. アルペジオ表示更新開始" if loop_count == 1
  update_arpeggio_display
  puts "21. アルペジオ表示更新完了" if loop_count == 1
  
  puts "22. LED表示開始" if loop_count == 1
  $led.show_hex(*$colors)
  puts "23. LED表示完了" if loop_count == 1
  
  puts "24. スリープ開始" if loop_count == 1
  sleep_ms(25)
  puts "25. スリープ完了" if loop_count == 1
end
