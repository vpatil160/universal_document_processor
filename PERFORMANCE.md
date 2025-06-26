# Performance Guide - Universal Document Processor

This guide provides detailed performance information, benchmarks, and optimization strategies for the Universal Document Processor gem.

## 📊 Performance Benchmarks

### Test Environment
- **OS**: Windows 10
- **Ruby**: 3.x
- **Hardware**: Standard development machine
- **Files**: Various synthetic test files

### Processing Time by File Size

| File Size | Text Files | CSV Files | JSON Files | TSV Files |
|-----------|------------|-----------|------------|-----------|
| 1 KB      | ~30 ms     | ~35 ms    | ~32 ms     | ~36 ms    |
| 100 KB    | ~50 ms     | ~80 ms    | ~60 ms     | ~85 ms    |
| 1 MB      | ~270 ms    | ~400 ms   | ~350 ms    | ~420 ms   |
| 5 MB      | ~1.25 s    | ~2.1 s    | ~1.8 s     | ~2.2 s    |

### Memory Usage Patterns

| File Size | Peak Memory Usage | Steady State |
|-----------|-------------------|--------------|
| 1 KB      | +36 KB           | Baseline     |
| 100 KB    | +200 KB          | Baseline     |
| 1 MB      | +2.5 MB          | Baseline     |
| 5 MB      | +12 MB           | Baseline     |

## ⚡ Performance Characteristics

### Linear Scaling
- **Text files**: Near-linear scaling with file size
- **CSV/TSV files**: Linear with slight parsing overhead
- **JSON files**: Depends on structure complexity
- **XML files**: Varies significantly with nesting depth

### Format-Specific Performance

#### Text Files (.txt, .md, .log)
```ruby
# Fastest processing - simple file reading
# Performance: O(n) where n = file size
# Memory: ~1.5x file size during processing
```

#### CSV Files (.csv)
```ruby
# Good performance with parsing overhead
# Performance: O(n*m) where n = rows, m = columns
# Memory: ~2-3x file size (stores parsed structure)
```

#### TSV Files (.tsv, .tab)
```ruby
# Similar to CSV with tab delimiter
# Performance: O(n*m) where n = rows, m = columns  
# Memory: ~2-3x file size
```

#### JSON Files (.json)
```ruby
# Performance depends on structure
# Simple JSON: ~1.5x slower than text
# Complex nested JSON: ~3x slower than text
# Memory: ~2-4x file size depending on structure
```

#### XML Files (.xml)
```ruby
# Performance varies with complexity
# Simple XML: ~2x slower than text
# Complex nested XML: ~5x slower than text
# Memory: ~3-5x file size
```

## 🚀 Optimization Strategies

### 1. File Size Management

```ruby
# Check file size before processing
def process_with_size_check(file_path)
  file_size = File.size(file_path)
  
  case file_size
  when 0..100_000          # < 100 KB
    # Process immediately - excellent performance
    UniversalDocumentProcessor.process(file_path)
    
  when 100_001..1_000_000  # 100 KB - 1 MB
    # Good performance - consider async for UI
    puts "Processing medium file (#{file_size / 1000} KB)..."
    UniversalDocumentProcessor.process(file_path)
    
  when 1_000_001..10_000_000  # 1 MB - 10 MB
    # Consider background processing
    puts "Processing large file (#{file_size / 1_000_000} MB)..."
    puts "This may take #{estimate_processing_time(file_size)} seconds"
    UniversalDocumentProcessor.process(file_path)
    
  else  # > 10 MB
    # Recommend chunking or streaming
    puts "Very large file detected (#{file_size / 1_000_000} MB)"
    puts "Consider processing in chunks"
    process_large_file_in_chunks(file_path)
  end
end

def estimate_processing_time(file_size_bytes)
  # Rough estimate based on benchmarks
  (file_size_bytes / 4_000_000.0).round(1)  # ~4MB per second
end
```

### 2. Batch Processing Optimization

```ruby
# Smart batch sizing based on file sizes
def optimize_batch_processing(files)
  # Group files by size for optimal batching
  small_files = files.select { |f| File.size(f) < 100_000 }
  medium_files = files.select { |f| File.size(f).between?(100_000, 1_000_000) }
  large_files = files.select { |f| File.size(f) > 1_000_000 }
  
  results = []
  
  # Process small files in large batches
  small_files.each_slice(20) do |batch|
    results.concat(UniversalDocumentProcessor.batch_process(batch))
  end
  
  # Process medium files in smaller batches
  medium_files.each_slice(5) do |batch|
    results.concat(UniversalDocumentProcessor.batch_process(batch))
  end
  
  # Process large files individually
  large_files.each do |file|
    results << UniversalDocumentProcessor.process(file)
  end
  
  results
end
```

### 3. Memory-Efficient Processing

```ruby
# Process large datasets without memory buildup
def memory_efficient_processing(file_paths)
  file_paths.each_with_index do |path, index|
    puts "Processing #{index + 1}/#{file_paths.length}: #{File.basename(path)}"
    
    # Process file
    result = UniversalDocumentProcessor.process(path)
    
    # Extract only essential data
    summary = extract_summary(result)
    
    # Save or process immediately
    save_result(summary, path)
    
    # Force garbage collection for large files
    if File.size(path) > 5_000_000
      GC.start
    end
    
    # Optional: Progress callback
    yield(index + 1, file_paths.length, summary) if block_given?
  end
end

def extract_summary(result)
  {
    format: result[:metadata][:format],
    size: result[:metadata][:file_size],
    text_preview: result[:text_content]&.slice(0, 500),
    table_count: result[:tables]&.length || 0,
    has_structured_data: !result[:structured_data].nil?
  }
end
```

### 4. Asynchronous Processing

```ruby
require 'concurrent-ruby'

# Process files asynchronously
def async_process_files(file_paths, max_threads: 4)
  # Create thread pool
  pool = Concurrent::FixedThreadPool.new(max_threads)
  
  # Submit processing tasks
  futures = file_paths.map do |path|
    Concurrent::Future.execute(executor: pool) do
      {
        file: path,
        result: UniversalDocumentProcessor.process(path),
        processed_at: Time.now
      }
    end
  end
  
  # Wait for completion and collect results
  results = futures.map(&:value)
  
  # Shutdown thread pool
  pool.shutdown
  pool.wait_for_termination
  
  results
end
```

## 📈 Performance Monitoring

### Built-in Performance Tracking

```ruby
require 'benchmark'

def process_with_detailed_metrics(file_path)
  file_size = File.size(file_path)
  
  # Memory before processing
  memory_before = get_memory_usage
  
  # Time the processing
  result = nil
  time_taken = Benchmark.realtime do
    result = UniversalDocumentProcessor.process(file_path)
  end
  
  # Memory after processing
  memory_after = get_memory_usage
  memory_used = memory_after - memory_before
  
  # Calculate metrics
  throughput = file_size / time_taken / 1024 / 1024  # MB/s
  memory_efficiency = memory_used.to_f / file_size
  
  {
    result: result,
    metrics: {
      file_size: file_size,
      processing_time: time_taken,
      throughput_mbps: throughput.round(2),
      memory_used: memory_used,
      memory_efficiency: memory_efficiency.round(2)
    }
  }
end

def get_memory_usage
  # Platform-specific memory usage detection
  if RUBY_PLATFORM =~ /win32/
    `tasklist /FI "PID eq #{Process.pid}" /FO CSV`.split("\n")[1]&.split(",")&.[](4)&.gsub(/[",]/, '')&.to_i || 0
  else
    `ps -o rss= -p #{Process.pid}`.strip.to_i
  end
end
```

### Performance Alerts

```ruby
class PerformanceMonitor
  THRESHOLDS = {
    processing_time: 5.0,      # seconds
    memory_usage: 100_000,     # KB
    throughput: 1.0            # MB/s minimum
  }
  
  def self.monitor_processing(file_path)
    metrics = process_with_detailed_metrics(file_path)
    
    alerts = []
    
    if metrics[:metrics][:processing_time] > THRESHOLDS[:processing_time]
      alerts << "Slow processing: #{metrics[:metrics][:processing_time].round(2)}s"
    end
    
    if metrics[:metrics][:memory_used] > THRESHOLDS[:memory_usage]
      alerts << "High memory usage: #{metrics[:metrics][:memory_used] / 1024}MB"
    end
    
    if metrics[:metrics][:throughput_mbps] < THRESHOLDS[:throughput]
      alerts << "Low throughput: #{metrics[:metrics][:throughput_mbps]}MB/s"
    end
    
    unless alerts.empty?
      puts "⚠️  Performance Alerts for #{File.basename(file_path)}:"
      alerts.each { |alert| puts "   - #{alert}" }
    end
    
    metrics
  end
end
```

## 🎯 Production Optimization

### Configuration for Production

```ruby
class ProductionProcessor
  def initialize
    @config = {
      max_file_size: 50_000_000,        # 50 MB limit
      batch_size_small: 50,             # Files < 100KB
      batch_size_medium: 10,            # Files 100KB-1MB
      batch_size_large: 1,              # Files > 1MB
      enable_gc_after_large: true,      # GC after large files
      performance_monitoring: true,
      async_processing: true,
      max_concurrent_threads: 4
    }
  end
  
  def process_files(file_paths)
    validate_files(file_paths)
    
    if @config[:async_processing] && file_paths.length > 1
      async_process_files(file_paths)
    else
      sequential_process_files(file_paths)
    end
  end
  
  private
  
  def validate_files(file_paths)
    file_paths.each do |path|
      raise "File not found: #{path}" unless File.exist?(path)
      
      size = File.size(path)
      if size > @config[:max_file_size]
        raise "File too large: #{path} (#{size / 1_000_000}MB > #{@config[:max_file_size] / 1_000_000}MB)"
      end
    end
  end
end
```

### Caching Strategy

```ruby
require 'digest'

class CachedProcessor
  def initialize(cache_dir: './cache')
    @cache_dir = cache_dir
    Dir.mkdir(@cache_dir) unless Dir.exist?(@cache_dir)
  end
  
  def process_with_cache(file_path)
    # Generate cache key based on file content and modification time
    file_stat = File.stat(file_path)
    cache_key = Digest::SHA256.hexdigest("#{file_path}:#{file_stat.mtime}:#{file_stat.size}")
    cache_file = File.join(@cache_dir, "#{cache_key}.json")
    
    # Return cached result if available
    if File.exist?(cache_file)
      puts "Using cached result for #{File.basename(file_path)}"
      return JSON.parse(File.read(cache_file), symbolize_names: true)
    end
    
    # Process and cache result
    result = UniversalDocumentProcessor.process(file_path)
    File.write(cache_file, JSON.pretty_generate(result))
    
    result
  end
  
  def clear_cache
    Dir.glob(File.join(@cache_dir, "*.json")).each { |f| File.delete(f) }
  end
end
```

## 📋 Performance Checklist

### Before Processing Large Batches

- [ ] Check available system memory
- [ ] Estimate total processing time
- [ ] Plan for progress reporting
- [ ] Consider async processing for > 10 files
- [ ] Set up error handling for individual files
- [ ] Plan for result storage/processing

### During Processing

- [ ] Monitor memory usage
- [ ] Track processing progress
- [ ] Handle errors gracefully
- [ ] Log performance metrics
- [ ] Provide user feedback

### After Processing

- [ ] Clean up temporary files
- [ ] Force garbage collection if needed
- [ ] Log final performance summary
- [ ] Archive or process results
- [ ] Update performance baselines

## 🔧 Troubleshooting Performance Issues

### Slow Processing

```ruby
# Diagnose slow processing
def diagnose_slow_processing(file_path)
  puts "Diagnosing: #{file_path}"
  
  file_size = File.size(file_path)
  puts "File size: #{file_size / 1024}KB"
  
  # Check file format
  format = File.extname(file_path).downcase
  puts "Format: #{format}"
  
  # Expected processing time
  expected_time = estimate_processing_time(file_size)
  puts "Expected time: ~#{expected_time}s"
  
  # Actual processing with timing
  actual_time = Benchmark.realtime do
    UniversalDocumentProcessor.process(file_path)
  end
  
  puts "Actual time: #{actual_time.round(2)}s"
  
  if actual_time > expected_time * 2
    puts "⚠️  Processing significantly slower than expected"
    puts "Consider:"
    puts "- File complexity (nested structures, encoding issues)"
    puts "- System resources (memory, CPU)"
    puts "- Concurrent processing load"
  end
end
```

### Memory Issues

```ruby
# Monitor memory during processing
def process_with_memory_monitoring(file_path)
  initial_memory = get_memory_usage
  peak_memory = initial_memory
  
  # Process with periodic memory checks
  result = nil
  thread = Thread.new do
    loop do
      current_memory = get_memory_usage
      peak_memory = [peak_memory, current_memory].max
      sleep 0.1
    end
  end
  
  result = UniversalDocumentProcessor.process(file_path)
  thread.kill
  
  final_memory = get_memory_usage
  
  puts "Memory usage:"
  puts "  Initial: #{initial_memory / 1024}MB"
  puts "  Peak: #{peak_memory / 1024}MB"
  puts "  Final: #{final_memory / 1024}MB"
  puts "  Increase: #{(peak_memory - initial_memory) / 1024}MB"
  
  result
end
```

---

## 📞 Performance Support

For performance-related issues:
- Check system resources (RAM, CPU)
- Review file characteristics (size, format, complexity)
- Consider batch processing strategies
- Monitor memory usage patterns
- Use async processing for large datasets

Performance optimization is an ongoing process. Monitor your specific use cases and adjust strategies accordingly. 