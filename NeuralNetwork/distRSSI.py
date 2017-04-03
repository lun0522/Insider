import tensorflow as tf
import numpy as np
from matplotlib import pyplot as plt


def draw_scatter():
    filename_queue = tf.train.string_input_producer(["NeuralDataModified.csv"])
    reader = tf.TextLineReader(skip_header_lines=1)
    key, value = reader.read(filename_queue)

    record_defaults = [[1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0]]
    col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12 = \
        tf.decode_csv(value, record_defaults=record_defaults)

    total = 5000
    xi = []
    yi = []
    pi = []
    pi_xi = []
    pi_yi = []
    pi_xi2 = []
    pi_xi_yi = []

    with tf.Session() as sess:
        tf.global_variables_initializer().run()

        coord = tf.train.Coordinator()
        threads = tf.train.start_queue_runners(coord=coord)

        for i in range(total):
            rssi, variance, beacon_x, beacon_y, device_x, device_y, beacon_roll, beacon_pitch, beacon_yaw, device_roll, \
            device_pitch, device_yaw = sess.run(
                [col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12])

            xi.append(np.log10(np.sqrt(np.square(device_x - beacon_x) + np.square(device_y - beacon_y))))
            yi.append(rssi)
            pi.append(20 / variance)
            pi_xi.append(pi[i] * xi[i])
            pi_yi.append(pi[i] * yi[i])
            pi_xi2.append(pi[i] * np.square(xi[i]))
            pi_xi_yi.append(pi[i] * xi[i] * yi[i])

        b = (np.sum(pi) * np.sum(pi_xi_yi) - np.sum(pi_xi) * np.sum(pi_yi)) / \
            (np.sum(pi) * np.sum(pi_xi2) - np.square(np.sum(pi_xi)))
        a = (np.sum(pi_yi) - b * np.sum(pi_xi)) / np.sum(pi)

        plt.scatter(xi, yi, s=pi, alpha=0.5)

        X = np.linspace(2, 3, 2, endpoint=True)
        Y = a + b * X
        plt.plot(X, Y, color="red", alpha=0.7, linewidth=2.5, linestyle="-")

        plt.title(r'$RSSI = - ' + str(np.around(np.abs(a), decimals=2)) + ' - ' + str(np.around(np.abs(b), decimals=2))
                  + ' \cdot log_{10}d$', fontsize=28)
        plt.xlabel(r'$log_{10}d$', fontsize=16)
        plt.ylabel(r'$RSSI\,(dB)$', fontsize=16)

        plt.show()

        coord.request_stop()
        coord.join(threads)
