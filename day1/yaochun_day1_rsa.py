import rsa
import hashlib

# 生成公私钥对
# 此函数利用 rsa 库的 newkeys 方法生成一个 2048 位的 RSA 公私钥对
# 公钥用于验证签名，私钥用于生成签名
def generate_key_pair():
    # 使用 rsa.newkeys(2048) 生成 2048 位的 RSA 公私钥对
    # 返回值是一个包含公钥和私钥的元组
    (pubkey, privkey) = rsa.newkeys(2048)
    return pubkey, privkey

# 实现 POW（工作量证明），找到符合条件的 nonce
# 工作量证明机制用于确保一定的计算工作量被完成
# 这里要求消息的哈希值以 4 个 0 开头
def proof_of_work(data, difficulty=4):
    """
    工作量证明函数
    :param data: 原始数据
    :param difficulty: 难度系数（前导零的个数）
    :return: (message, hex_dig)
    """
    nonce = 0
    target = '0' * difficulty
    while True:
        message = data + str(nonce)
        hash_object = hashlib.sha256(message.encode())
        hex_dig = hash_object.hexdigest()
        if hex_dig[:difficulty] == target:
            return message, hex_dig
        nonce += 1

# 私钥签名
# 此函数使用私钥对消息进行签名
# 签名可以确保消息的来源和完整性
def sign_message(privkey, message):
    # 使用 rsa.sign 方法对消息进行签名
    # 消息需要先编码为字节类型，签名算法选择 SHA - 256
    signature = rsa.sign(message.encode(), privkey, 'SHA-256')
    return signature

# 公钥验证
# 此函数使用公钥验证签名的有效性
# 通过公钥验证可以确认消息是否由对应的私钥签名
def verify_signature(pubkey, message, signature):
    try:
        # 使用 rsa.verify 方法验证签名
        # 如果签名有效，该方法不会抛出异常
        rsa.verify(message.encode(), signature, pubkey)
        return True
    except rsa.VerificationError:
        # 如果签名无效，会抛出 VerificationError 异常，捕获该异常并返回 False
        return False

# 主函数，将整个流程串起来
def main():
    try:
        # 生成公私钥对
        print("正在生成密钥对...")
        pubkey, privkey = generate_key_pair()
        print("密钥对生成成功！\n")

        # 进行 POW
        data = "sinycat"
        print(f"原始数据: {data}")
        print("正在进行工作量证明...")
        message, hash_value = proof_of_work(data, difficulty=4)
        print(f"POW 完成！")
        print(f"最终消息: {message}")
        print(f"哈希值: {hash_value}\n")

        # 签名和验证
        print("正在生成签名...")
        signature = sign_message(privkey, message)
        print(f"签名生成成功！")
        print(f"签名（十六进制）: {signature.hex()}\n")

        print("正在验证签名...")
        is_valid = verify_signature(pubkey, message, signature)
        print(f"签名验证结果: {'✓ 有效' if is_valid else '✗ 无效'}\n")

    except Exception as e:
        print(f"发生错误: {str(e)}")

if __name__ == "__main__":
    # 程序入口，调用主函数
    main()