# ランダムカラー表示デモ - 本当に鮮やかな色変化版
# 内蔵5x5 LED(GPIO 27) + 各色成分を独立させた変化

require 'ws2812'

puts "ATOM Matrix Internal LED Starting..."

# LED設定
led_pin = 27
led_count = 25

# WS2812初期化
led = WS2812.new(RMTDriver.new(led_pin))

puts "LED initialized (GPIO 27, 25 LEDs)"

puts "Starting vivid color display..."

# 色配列初期化
colors = Array.new(led_count) { [0, 0, 0] }

puts "Starting continuous LED display..."

# 連続点灯ループ
loop do
  time_seed = Time.now.to_i
  
  # 毎回色を大胆に変化させてLED更新
  led_count.times do |i|
    # 各LEDと各色成分で全然違う計算をする
    r_seed = time_seed * 7 + i * 13
    g_seed = time_seed * 11 + i * 17
    b_seed = time_seed * 19 + i * 23
    
    # 各色成分を0か高い値かの二択で鮮やかに
    r = (r_seed % 7 < 2) ? 0 : (r_seed % 40 + 10)
    g = (g_seed % 7 < 2) ? 0 : (g_seed % 40 + 10) 
    b = (b_seed % 7 < 2) ? 0 : (b_seed % 40 + 10)
    
    colors[i] = [r, g, b]
  end
  
  # LED表示更新
  led.show_rgb(*colors)
  
  sleep_ms 150
end
