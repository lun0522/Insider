import tensorflow as tf
from matplotlib import pyplot as plt


def draw_arrow():
    filename_queue = tf.train.string_input_producer(["SingleBeacon.csv"])
    reader = tf.TextLineReader(skip_header_lines=1)
    key, value = reader.read(filename_queue)

    record_defaults = [[1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0]]
    col1, col2, col3, col4, col5, col6, col7 = tf.decode_csv(value, record_defaults=record_defaults)

    with tf.Session() as sess:
        coord = tf.train.Coordinator()
        threads = tf.train.start_queue_runners(coord=coord)

        for i in range(502):
            rssi, variance, x_base, y_base, x_length, y_length, color = sess.run(
                [col1, col2, col3, col4, col5, col6, col7])

            ax = plt.axes()
            ax.arrow(x_base, y_base, x_length * 15, y_length * 15, width=2, head_width=4, head_length=10,
                     color=(1, 1 - color, 0))

        plt.xlim([-500, 200])
        plt.ylim([0, 1000])
        plt.show()

        coord.request_stop()
        coord.join(threads)
