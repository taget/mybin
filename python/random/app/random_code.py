import random

def get_random(length):
    """
        will return a interger number with lengh
    """
    if length == 0:
        return 0
    left = 10 ** (length -1)
    right = 10 ** length  - 1

    return random.randint(left, right)

def get_random_str(length):
    return str(get_random(length))

