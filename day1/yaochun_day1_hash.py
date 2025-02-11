import hashlib
import time

# hash difficulty
def pow_with_difficulty(difficulty):
    base_string = "sinycat"
    nonce = 0
    start_time = time.time()
    last_print_time = start_time

    while True:
        current_time = time.time()
        if current_time - last_print_time >= 10:
            print(f"正在计算中......{time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(current_time))}")
            last_print_time = current_time

        data = base_string + str(nonce)
        hash_object = hashlib.sha256(data.encode())
        hex_dig = hash_object.hexdigest()

        if hex_dig.startswith('0' * difficulty):
            end_time = time.time()
            elapsed_time = end_time - start_time
            print(f"找到满足 {difficulty} 个 0 开头的哈希值：")
            print(f"花费时间: {elapsed_time} 秒")
            print(f"Hash 的内容: {data}")
            print(f"Hash 值: {hex_dig}")
            print(f"Nonce: {nonce}")
            break

        nonce += 1


# pow_with_difficulty(5)
pow_with_difficulty(6)
