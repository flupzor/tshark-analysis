class NewBlock(object):
    def __init__(self, start_block):
        self.start_block = start_block
        self.end_block = None

    def __str__(self):
        return '{} -> {}'.format(self.start_block, self.end_block)


def reduce_time_block(times):
    new_block = None
    for block in times:
        if new_block and block.start_block != new_block.end_block:
            yield new_block
            new_block = None
        if new_block is None:
            new_block = NewBlock(block.start_block)
        new_block.end_block = block.end_block
    if new_block:
        yield new_block

