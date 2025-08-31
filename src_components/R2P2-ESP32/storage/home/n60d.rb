# ペンライトデモ - VL53L0X距離センサーによる輝度制御
# 外付け60 LED(J5ポートGPIO 22) + VL53L0X測距センサー(I2C GPIO 21/25)

require 'ws2812'
require 'i2c'
require 'vl53l0x'

led_pin = 22
led_count = 60

led = WS2812.new(RMTDriver.new(led_pin))

vl53l0x = VL53L0X.new(I2C.new(
  unit: :ESP32_I2C0,
  frequency: 100_000,
  sda_pin: 25,
  scl_pin: 21,
  timeout: 2000
))

unless vl53l0x.ready?
  puts "Failed to initialize VL53L0X sensor"
end

# 距離に応じたスペクトラム色計算
colors = Array.new(led_count) { [0, 0, 0] }

loop do
  distance = vl53l0x.read_distance
  
  if distance > 0 && distance <= 2000
    # 距離を0-1の範囲に正規化
    normalized = distance / 2000.0
    
    # RGB スペクトラム計算（赤→緑→青）
    if normalized < 0.5
      # 近距離: 赤→緑へ遷移
      ratio = normalized * 2
      r = (255 * (1 - ratio)).to_i
      g = (255 * ratio).to_i
      b = 0
    else
      # 遠距離: 緑→青へ遷移
      ratio = (normalized - 0.5) * 2
      r = 0
      g = (255 * (1 - ratio)).to_i
      b = (255 * ratio).to_i
    end
    
    puts "Distance: #{distance}mm, RGB: [#{r}, #{g}, #{b}]"
    
    # 全LEDに同色適用
    led_count.times do |i|
      colors[i] = [r, g, b]
    end
  else
    # センサー範囲外は消灯
    led_count.times do |i|
      colors[i] = [0, 0, 0]
    end
  end
  
  led.show_rgb(*colors)
  sleep_ms 100
end