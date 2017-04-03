import tensorflow as tf
import numpy as np


def run_network():
    filename_queue = tf.train.string_input_producer(["NeuralDataModified.csv"])
    reader = tf.TextLineReader(skip_header_lines=1)
    key, value = reader.read(filename_queue)

    record_defaults = [[1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0], [1.0]]
    col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12 = \
        tf.decode_csv(value, record_defaults=record_defaults)

    # sample size
    total = 5000
    train_size = np.int(total * 0.9 / 10) * 10
    test_size = total - train_size
    # number of inputs and output
    inNum = 6
    outNum = 1
    batch_size = 10
    # input X
    XX = tf.placeholder(tf.float32, [None, inNum])
    # correct answers will go here
    Y_ = tf.placeholder(tf.float32, [None, outNum])
    # for linear regression
    xi = []
    yi = []
    pi = []
    pixi = []
    piyi = []
    pixi2 = []
    pixiyi = []
    data_batch = []
    result_batch = []
    # layers and their number of neurons
    L = 10
    # weights
    W1 = tf.Variable(tf.truncated_normal([inNum, L], stddev=1))
    W2 = tf.Variable(tf.truncated_normal([L, outNum], stddev=1))
    # biases
    B1 = tf.Variable(tf.ones([L]) / 10)
    B2 = tf.Variable(tf.ones([outNum]) / 10)

    # the model
    Y1 = tf.nn.tanh(tf.matmul(XX, W1) + B1)
    YY = tf.nn.tanh(tf.matmul(Y1, W2) + B2)

    # loss function: difference = (predicted_distance - read_distance)^2
    #  where YY: the computed output vector
    #        Y_: the desired output vector
    difference = tf.reduce_sum(tf.sqrt(tf.abs(YY - Y_)))

    # training, learning rate = 0.05
    train_step = tf.train.GradientDescentOptimizer(0.05).minimize(difference)

    with tf.Session() as sess:
        tf.global_variables_initializer().run()

        coord = tf.train.Coordinator()
        threads = tf.train.start_queue_runners(coord=coord)

        for i in range(train_size):
            rssi, variance, beacon_x, beacon_y, device_x, device_y, beacon_roll, beacon_pitch, beacon_yaw, device_roll, \
            device_pitch, device_yaw = sess.run(
                [col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12])

            distorted_x = device_x - beacon_x + np.random.rand() * 100 - 50
            distorted_y = device_y - beacon_y + np.random.rand() * 100 - 50
            distorted_dist = np.sqrt(np.square(distorted_x) + np.square(distorted_y))

            xi.append(np.log10(np.sqrt(np.square(device_x - beacon_x) + np.square(device_y - beacon_y))))
            yi.append(rssi)
            pi.append(30 / variance)
            pixi.append(pi[i] * xi[i])
            piyi.append(pi[i] * yi[i])
            pixi2.append(pi[i] * np.square(xi[i]))
            pixiyi.append(pi[i] * xi[i] * yi[i])

            data_batch.append((rssi + 60) / 30)
            data_batch.append(distorted_x / distorted_dist)
            data_batch.append(distorted_y / distorted_dist)
            data_batch.append((beacon_roll - device_roll) / 180)
            data_batch.append((beacon_pitch - device_pitch) / 180)
            data_batch.append((beacon_yaw - device_yaw) / 180)

            result_batch.append(np.sqrt(np.square(device_x - beacon_x) + np.square(device_y - beacon_y)) / 1000)

            if (i + 1) % batch_size == 0:
                train_data = {XX: np.reshape(np.array(data_batch), [batch_size, inNum]),
                              Y_: np.reshape(np.array(result_batch), [batch_size, outNum])}

                # train
                sess.run(train_step, feed_dict=train_data)
                print(B2.eval())

                data_batch.clear()
                result_batch.clear()

        b = (np.sum(pi) * np.sum(pixiyi) - np.sum(pixi) * np.sum(piyi)) / \
            (np.sum(pi) * np.sum(pixi2) - np.square(np.sum(pixi)))
        a = (np.sum(piyi) - b * np.sum(pixi)) / np.sum(pi)

        print('a:', a, 'b:', b)
        sum_nn = 0
        sum_dr = 0
        max_nn = 0

        for i in range(test_size):
            rssi, variance, beacon_x, beacon_y, device_x, device_y, beacon_roll, beacon_pitch, beacon_yaw, device_roll, \
            device_pitch, device_yaw = sess.run(
                [col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12])

            distorted_x = device_x - beacon_x + np.random.rand() * 100 - 50
            distorted_y = device_y - beacon_y + np.random.rand() * 100 - 50
            distorted_dist = np.sqrt(np.square(distorted_x) + np.square(distorted_y))

            test_data = {XX: np.reshape([(rssi + 60) / 30,
                                         distorted_x / distorted_dist,
                                         distorted_y / distorted_dist,
                                         (beacon_roll - device_roll) / 180,
                                         (beacon_pitch - device_pitch) / 180,
                                         (beacon_yaw - device_yaw) / 180],
                                        [-1, inNum]),
                         Y_: np.reshape(
                             [np.sqrt(np.square(device_x - beacon_x) + np.square(device_y - beacon_y)) / 1000],
                             [-1, outNum])}

            # test
            y_, yy = sess.run([Y_, YY], feed_dict=test_data)
            sum_nn += np.abs(yy * 10 - y_ * 10)
            sum_dr += np.abs(np.power(10, (rssi - a) / b) / 100 - y_ * 10)

            if np.abs(yy * 10 - y_ * 10) > max_nn:
                max_nn = np.abs(yy * 10 - y_ * 10)

            print(i, ':', y_ * 10, yy * 10, np.abs(yy * 10 - y_ * 10),
                  np.abs(np.power(10, (rssi - a) / b) / 100 - y_ * 10), variance)

        print('nn:', sum_nn / test_size, 'dr:', sum_dr / test_size)
        print('max_nn:', max_nn)

        coord.request_stop()
        coord.join(threads)
