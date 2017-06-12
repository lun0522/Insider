import tensorflow as tf
import numpy as np
from matplotlib import pyplot as plt


def draw_scatter():
    filename_queue = tf.train.string_input_producer(["finalData.csv"])
    reader = tf.TextLineReader(skip_header_lines=1)
    key, value = reader.read(filename_queue)

    record_defaults = [[1.0], [1.0], [1.0], [1.0], [1.0], [1.0]]
    col1, col2, col3, col4, col5, col6 = tf.decode_csv(value, record_defaults=record_defaults)

    total = 2796
    xi = []
    yi = []
    xiyi = []
    xi2 = []

    dist_x = []
    dist_y = []
    beacon_heading = []

    with tf.Session() as sess:
        tf.global_variables_initializer().run()

        coord = tf.train.Coordinator()
        threads = tf.train.start_queue_runners(coord=coord)

        for i in range(total):
            x, y, rela_head, beacon_head, pitch, rssi = sess.run([col1, col2, col3, col4, col5, col6])

            xi.append(np.log10(np.sqrt(np.square(x) + np.square(y))))
            yi.append(rssi)
            xiyi.append(xi[i] * yi[i])
            xi2.append(np.square(xi[i]))

            dist_x.append(x)
            dist_y.append(y)
            beacon_heading.append(beacon_head)

        b = (np.sum(xiyi) - np.sum(xi) * np.sum(yi) / total) / (np.sum(xi2) - np.square(np.sum(xi)) / total)
        a = np.mean(yi) - b * np.mean(xi)

        plt.scatter(xi, yi, alpha=0.4, s=20)

        X = np.linspace(2, 3, 2, endpoint=True)
        Y = a + b * X
        plt.plot(X, Y, color="red", alpha=0.7, linewidth=2.5, linestyle="-")

        plt.title(r'$RSSI = - ' + str(np.around(np.abs(a), decimals=2)) + ' - ' + str(np.around(np.abs(b), decimals=2))
                  + ' \cdot log_{10}d$', fontsize=16)
        plt.xlabel(r'$log_{10}d$', fontsize=16)
        plt.ylabel(r'$RSSI\,(dB)$', fontsize=16)

        # max_rssi = np.max(yi)
        # min_rssi = np.min(yi)
        #
        # for i in range(total):
        #     plt.scatter(dist_x[i] * np.cos(beacon_heading[i] * np.pi / 180) +
        #                 dist_y[i] * np.sin(beacon_heading[i] * np.pi / 180),
        #                 - dist_x[i] * np.sin(beacon_heading[i] * np.pi / 180) +
        #                 dist_y[i] * np.cos(beacon_heading[i] * np.pi / 180),
        #                 c=(1, 1 - (yi[i] - min_rssi) / (max_rssi - min_rssi), 0))

        plt.show()

        coord.request_stop()
        coord.join(threads)
