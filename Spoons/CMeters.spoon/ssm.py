#!/usr/bin/env python3
import psutil
import time
from collections import defaultdict as ddict
import pprint


def main(samples=3):
    """Calculate system stats using psutil and returning it as key:value pairs"""
    stats = ddict(list)
    for i in range(samples):
        # stats['sec'].append(int(time.strftime('%S')))
        stats['cpu'].append(psutil.cpu_percent(percpu=False))
        io_counter = psutil.net_io_counters()
        stats['netIn'].append(io_counter.bytes_recv)
        stats['netOut'].append(io_counter.bytes_sent)
        time.sleep(1)

    for i in range(1, samples):
        stats['delta_netIn'].append((stats['netIn'][i] - stats['netIn'][i-1]) / 1024 / 1024)
        stats['delta_netOut'].append((stats['netOut'][i] - stats['netOut'][i-1]) / 1024 / 1024)

    averaged_stats = {
        'cpu' : sum(stats['cpu']) / samples,
        'netIn' : sum(stats['delta_netIn']) / (samples - 1), # in MB
        'netOut' : sum(stats['delta_netOut']) / (samples - 1), # in MB
        'currentSecond' : time.strftime('%S'),
        'currentMinute' : time.strftime('%M'),
        'currentHour' : time.strftime('%H'),
    }
    for k, v in averaged_stats.items():
        print(f'{k}:{v}', end=' ')


if __name__ == '__main__':
    main()

