import tensorflow as tf
from matplotlib import pyplot as plt
import numpy as np


def draw_arrow():
    filename_queue = tf.train.string_input_producer(["SingleBeacon.csv"])
    reader = tf.TextLineReader(skip_header_lines=1)
    key, value = reader.read(filename_queue)

    record_defaults = [[1.0], [1.0], [1.0], [1.0], [1.0]]
    col1, col2, col3, col4, col5 = tf.decode_csv(value, record_defaults=record_defaults)

    x = []
    y = []

    with tf.Session() as sess:
        coord = tf.train.Coordinator()
        threads = tf.train.start_queue_runners(coord=coord)

        for i in range(391):
            x_base, y_base, x_length, y_length, color = sess.run(
                [col1, col2, col3, col4, col5])

            x.append(x_base)
            y.append(y_base)

            ax = plt.axes()
            ax.arrow(x_base, y_base, x_length * 15, y_length * 15, width=2, head_width=4, head_length=10,
                     color=(1, 1 - color, 0))

        plt.scatter(x, y, s=8, c=(52 / 255, 162 / 255, 219 / 255), zorder=2)

        plt.xlim([0, 650])
        plt.ylim([50, 700])
        plt.show()

        coord.request_stop()
        coord.join(threads)


def draw_colormap():
    filename_queue = tf.train.string_input_producer(["SingleBeacon.csv"])
    reader = tf.TextLineReader(skip_header_lines=1)
    key, value = reader.read(filename_queue)

    record_defaults = [[1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0]]
    col1, col2, col3, col4, col5, col6, col7 = tf.decode_csv(value, record_defaults=record_defaults)

    total = 488
    rssi_arr = []
    rec_var_arr = []
    rssi_final = []
    last_x = 0.0

    with tf.Session() as sess:
        coord = tf.train.Coordinator()
        threads = tf.train.start_queue_runners(coord=coord)

        for i in range(total):
            rssi, variance, x_base, y_base, x_length, y_length, color = sess.run(
                [col1, col2, col3, col4, col5, col6, col7])

            if i > 0 and x_base != last_x:
                rssi_modified = 0.0

                for j in range(len(rssi_arr)):
                    weight = rec_var_arr[j] / np.sum(rec_var_arr)
                    rssi_modified += rssi_arr[j] * weight
                rssi_final.append(rssi_modified)
                rssi_arr.clear()
                rec_var_arr.clear()

            rssi_arr.append(rssi)
            rec_var_arr.append(1 / variance)
            last_x = x_base

            if i == total - 1:
                rssi_modified = 0.0
                for j in range(len(rssi_arr)):
                    weight = rec_var_arr[j] / np.sum(rec_var_arr)
                    rssi_modified += rssi_arr[j] * weight
                rssi_final.append(rssi_modified)

        rssi_reshaped = np.reshape(np.array(rssi_final[::-1]), [13, 10])
        plt.imshow(rssi_reshaped, interpolation='bilinear')

        an = np.linspace(0, 2 * np.pi, 100)
        for i in range(9):
            plt.plot((i + 1) * 2 * np.cos(an) + 10.5, (i + 1) * 2 * np.sin(an) - 0.5, color=(1, 1 - i / 8, 0))

        plt.xlim([-1.5, 10.5])
        plt.ylim([12.5 + 1.025, -0.5 - 1.079])
        plt.show()

        coord.request_stop()
        coord.join(threads)

