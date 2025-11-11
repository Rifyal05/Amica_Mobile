import 'package:amica/mainpage/create_post_page.dart';
import 'package:amica/models/post_model.dart';
import 'package:amica/mainpage/connect.dart';
import 'package:amica/mainpage/post_detail_page.dart';
import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late final TabController _mainTabController;
  late final TabController _savedTabController;

  bool _isCollectionPrivate = false;
  final bool isViewingOwnProfile = true;

  final List<Post> _userPosts = Post.dummyPosts.where((p) => p.user.id == 'user_001').toList();
  late final List<Post> _imagePosts;
  late final List<Post> _textPosts;
  late final List<Post> _savedImagePosts;
  late final List<Post> _savedTextPosts;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _savedTabController = TabController(length: 2, vsync: this);

    _imagePosts = _userPosts.where((p) => p.imageUrl != null || p.assetPath != null).toList();
    _textPosts = _userPosts.where((p) => p.imageUrl == null && p.assetPath == null).toList();

    final savedPosts = Post.dummyPosts.where((p) => p.user.id != 'user_001').toList();
    _savedImagePosts = savedPosts.where((p) => p.imageUrl != null || p.assetPath != null).toList();
    _savedTextPosts = savedPosts.where((p) => p.imageUrl == null && p.assetPath == null).toList();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _savedTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildProfileDetails(context),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _mainTabController,
                    indicatorColor: colorScheme.primary,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_outlined)),
                      Tab(icon: Icon(Icons.notes_outlined)),
                      Tab(icon: Icon(Icons.bookmark_border)),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _mainTabController,
            children: [
              Column(
                children: [
                  _buildCreatePostButton(),
                  const Divider(height: 1),
                  Expanded(child: _buildUserPostsGrid(_imagePosts)),
                ],
              ),
              Column(
                children: [
                  _buildCreatePostButton(),
                  const Divider(height: 1),
                  Expanded(child: _buildTextPostsList(_textPosts)),
                ],
              ),
              _buildSavedPostsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetails(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 160,
              child: ClipRRect(
                child: Image.network(
                  'https://images.pexels.com/photos/933054/pexels-photo-933054.jpeg?auto=compress&cs=tinysrgb&w=1260',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              child: CircleAvatar(
                radius: 54,
                backgroundColor: theme.colorScheme.surface,
                child: const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage('data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxMTEhUREhMVFRUXFhcWGRIYGBgTGBYXFRUWGBcaExUZHjQgGB4nGxcYJDEhJSkrLy4uGB8zODMvNyg5LisBCgoKDg0OGhAQGy0lHyYuLS8rMDctLTcvNS8tKy0tKy0tLy03LS0vLSsvLS0vLS0rLS0tLS0tLS4tNS0tLS0tLf/AABEIAOEA4QMBIgACEQEDEQH/xAAcAAEAAgMBAQEAAAAAAAAAAAAABQYDBAcCAQj/xABDEAACAQIEBAQDBAcGBAcAAAABAgADEQQFEiEiMUFRBhNhcTKBkQdCUqEUI5KxwdHwYnKywuHxFRYkMwgXQ1Njc6L/xAAaAQEAAwEBAQAAAAAAAAAAAAAAAgMEAQUG/8QALBEAAgIBBAECBAYDAAAAAAAAAAECAxEEEiExQRNhBVFxgSIjocHR8CRCkf/aAAwDAQACEQMRAD8A7jERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREARK9m/jDD4ZqQqhwlWt5C17DyxUBIIbi1AXBGrTbY7z1m2egYujl9NwtarTeqWsG8umgsOHqWblfojekA3cbnlGk7U3YBwKZCllBbzGZV0Am53UzxWzxFNQaXOhkUW0gVC9QU/1ZLWOlzpa9rEe1918GjaiwuWChtyLhCSu19tyZV8/wAVgMKtJmoeZrxC4cmnp1B3qKxNYlgag8xVLfFvzgEs/iJACTSqWUMX3pHQEbSb8fF3stz057TcwOZrVYooa6jjBsPLbURobfmbE7XFrHkwvk/4fS1K/lrdRpXYcIvfhHIb9plo4dVLsosXbUx33YIqX9OFFHygGWJpYXMletWoBXDURTLMVsjCqCV8tvvW0m/absAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAKFnXhrBY3Xh6C09NenXrvUSzBazGmKVRrHYli5A2vpf1kEcvqYPMsmfE1A1aomIp16xtZn8hQi6tuXCo76b8yZ1kCCoMHcnHvDWOxDVMBrdzjHxeLXGUSzG1EE6hVp3sqKPL0bWGoW+LeIwqUzlVADT5q5uqPa3mIGxDkBjzXkDb0BncMbXFNDU06jwiwsCSWCgXPqZoYnOkpqxek4ZXANPhJsRrNQEGxUIrt34CACbAhk5fmGZYjDrjBTqVThUzeklRy9R/LoFQ1ZfM3dU1aAbfiI6yVzTDotbK6dDF1KtKticRqqU6zBStSnqNOkyNsgvZbElR1vvL9luJpBjh6VPQVLs6AKAuprh2tz8wtqB5nivuptJ6RtsNuXp7QMlN8f5eaWXj9HrLROHZKwWo5C4gUF/7Nd2a7hlUc230i5tvJzwhjRWwWGrBXXXSRtLkuw26sfi97bixkuyg7EXn2DgiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAYsViUpo1So6oii7OxCqoHVmOwEp+J+1XK0bT+kFrbFkp1GX5MFsflecs+2DxRUxOMfChiKGHbQEB2aoPjdx1IN1HbT6mUKQcjTChNZZ+ssBj8NjqGujUFWk22pSykFSDY2syMNjbY8p6/4Hh+bUw54jeoTVuW0gk6ybmyKATyAsLCcg/8AD9i2GIxNG50NSWpboGR9N/QkP+Q7TuEknlFNkdssGvhcElP4BbgSnzJ4aerQNz01Hf1mxETpAREQBERAEREAREQBERAEREAREQBERAEREAREQBE+M1prPUJnG8ElHJmaqB6zx5/pMMSO5ligj84fapktTDZhWcg+XXdq1N+h1m7rfuGJ27WPWVJWJn6q8SmgMLWfFU0q0aaNUZHUODoBbYEc9tvWflurU1MzaVXUS2hRZVub2UdAOQkWaK3ng28qzjEYbX+j1npGoArsllYgEkAP8S7n7pExvmVcnUa9Yt+I1HJ+t5rROFuEXLwr9pOOwjgPUbEUb8VKqxY2/wDjqHiU/Mj0n6A8O57RxtBcRh21I2xB2ZGHNXHRh/qLg3n5Nls+z7xRVy+qKpBOFquKdXnbh+8h/EoN/UXHYiSlgpspUuV2fpZqgE8Gv6TADPs7uZnUEZPPPpPQr+kwFht67D12J2+QMTmWd2o21cHlPU05mp1eh+skpEHDHRmiIkiAiIgCIiAIiIAiIgCIiAJ8Jn2Ya7dJxvB1LLMdR7zxESsvSwIiIBA+PcO1TLsWigljQqEAczpXVYeu0/MKVJ+vJ+cftB8F1MJjTToU2elWJeiFBa1zxU9uWkn9kr6wTreGQuV5HiMQj1KFIuqc2uFuQL6VBPEbdBIkMTa29+QHM35WnZ/BuUVMNhBRqEByWfbfQWtwk9SO/wAvWUfwdlyVsyquBdKT1aqr3Iq2p7el7+6iURuzu+SNsqXiPzZI5L9nrCz4oazz8lX0qPSpU5k+ii39qePtKxKinh8MtMU9OpvLGmyr8CW07WPEflOhjj2N9uoJX9xnMPFGQYqtjMUUptUFJFqm258nhVdA5tbfYfgaVVTdk8suvrVMOCx/+bdX9FNFaHlVRTRKdcOKtiNIZmRlFjpBI5722lLfxLjS2o4zE3ve/nVB+Qa0h6b3nuaW2Yoxiui/ZP8AajiU8oYlRX8tmZXLeUSWXQPNKobhVapyUk3HbftGS5gMRQp11NMhxe9NzUTsQGZVOx23UEHa0/LM659g+PYri8OTdENKoo7NU8xX+uhfznUyFkEuUdXiIkikz0X6TNNMGbam8nFlU1g+xESRAREQBERAEREAREQDy7gbkge+0p759V1sdiLmykch03G8sedYcvT25qb279P4ylYlLN77yi2TR6nw+quae7kteV47zU1dev8AX9cpuSB8MkJRLuQoZwBfa5J0i3uxtJ6di8oovjGNkox6QiInSoSC8SPui9gT9bAfuMlsdjFpI1R72UXsBc/ISpvjfPY1B16fhHQGZtTYlHabdFU3Lf4Ridrb9JQ1wJwecIyj9VihUHsxGpx+2FPs3pL+6dDNfCZRTqVaYqsQKbmpTbbZvLdNLX6cd/dR3mWqXOPDPQuScdy8c/ybmDoF6ioBsebfhA5kyB8M43EU84xOAxLA+ZSYUWACjQpL0yLc7oXvz3QjpOh5bl4pA73J62tt2Ej80yAVcbhMYNmoCsCfxLUplVB9ixI9zNlNWxZfZ5up1HqPC6OW4HwBSFFUrgtUFyzU+A3sLqS3MDpt3PWw3/8AkfA2IFJyQQNqlS/Q9WtyInQM+yz/ANRBYb6gO/eQlOna/Yknnc3PP+v4TNZKcXhs3UxrsipJHPPFngviothrKah8s0zZACFZtZ0iwsqnVbnYcyd759j3hipg6WIesAHq1Aosbg06QIVh6Fnf5ASWy7IRUId7hQDpPfVa9h7DnLTSphVCjYAWE00ObXJh1Xpp4j2eoiJeZBNjDnaa8zYc852PZGfRniIlhSIiIAiIgCIiAIiYcRiVQcRt2HU27TjaSyzqTfCPmIqrfRcaiL6b7kAgEgdrkfWUv7SnahgquKoqPMQodwSLM6qxIHoec2PGYapTTFUCyvQJvbmEe1z6gEC/oTeaeD8RLisPWoVlXzDSqbWutSyHoeR9P9pVujPldFtdrqnjpmr4wxxQYVFGkKq1tHTVtp+lm+svaMCARyIuPYyhfaKh86m3Q07D5MT/AJhLrhyKVKmrsBZUXc2uwAFh3N50hFtzlk2TNWriOg+s94ttrd5qyEn4NUI+WeaqBgVbcEEEdwecgsqo+Qz0G5ltSN+NbAbHuLbiT8xYjDo40uoYc9+h7jsZnup9Re5qrs2pxfTIvHkorEC9xYLzuxIAFvcyvZvTrrtUXSpA5br7E9/ST+bZOhNGuDUDYZzUUB2IYEWcMDe/De3X5EzczPNEpaF+J6jKqIOupgoJPRbnnKYaTEcNltesVT6yQ3hRq5YHzHFJehJKk8gFB+u3aWwV27zHE01x2LGSq+xWz3YSN2hV1e8p2d46g1U6WsFGkgXAZgTc2Hxc7X9Ju+JMxNKlZTZ3uoPUD7x/O3zlFNTew3P5D3Mo1N3+ps+H6PObH9joeU+KKNRhTIKHYAtbSx7A9PnJ+chnRPCWYGrQ4jdkOgnqQACCfkbfKT0+oc3tkU6/QxpW+HXkmoiaOcZmuHQO/IuqftHc/Jbn5TYeS3gw5zmnlWVd2M18tz2o1VFKrZjpNgb79b3kf4kU/pG/4AR+Y/hPOW0G1ArfV922x95Vue49aOnq9DLXLRe4mPDqQqhjcgC57mZJqPCYiIgCIiAIiIAkbnWCLhWX4lP5H/YSSiQsrVkXFkoTcJbkVnAYxFxH6LU4ar0mcUyDxKrKCQbWPPl7ysZ54c01WOEOorZmoA8dO+4KA/Evt7b9Lr4jzTDUUH6Q1jzQD47jqh+77mw6dZQ8dnLV6i4jDrUNSjsWCg66d7guEJCkEkHoQzcuUqhUqo7ULbFY8ssrinVpYOrVG6G7X2KmnScuCP79MbekwZQ7YnEms3wpuB0W+yj35m/cTD4vxGhAy7pUcOpBuL6GVxcbfgPrd5l8JZ/RZRQK+W/qbioe4bv6H5SZzK3YZPYo8XtMU9VjxH3nmVPs9CPRgDFXsTdW3W/RgN19iNx7N6CZ5r482Qt+Cz/JTdre63HzmcGDpWM7xdTC4gVlBalVA10+hZRY6ezaQD62PaauRYFq2J88m9Kn8DfiAGmkB7LxH1b1luxFBXUo6hlPQi8hcFUWkpWndeIkJ8QsbbEne97m/rIymorkrjppTnldE9NJ65Dv7KPQAAn/ADflIHNvENQHRTstgLtzN/S+wkFXxDubuzMT3JMzz1MVwj1afh85cy4PfiHENWrtvwrwg9Nudh13vNWmgAsJ6hjbc7DvMUm5PJ7EIqEVFeBLv4CX9TUPepb6Kv8AOUPdvRfoW/kPzPtz6D4FP/Tt/wDa3+FJo0q/MMHxOX+O/qixTnnjjGGtiBQXkllA7u9rn8wPkZbHzIpivJY3RwpX+ySLW9QSPqZXsBlLVMyqsw4adQ1CfVuKmPzB9hPUPlbHuWEZcwNevm6YcbYajhxUqnSOJqhcIuoi43UEAfheXbBYRUHCLE9ev1lUxfiilR1EA1KjsW0g2AWwWnqbpdQGsLninnw9mGKxtYVGPl0KZuVS6hmHwqW5tvYnpty3nY4yTne2lDPBd4iJYVCIiAIiIAiIgCfCwHOfZGZzk6YgKHLDTfZSBe9udx6c5x5xwTgouWJPCJIiQGV061J2o1n1A70muTqtcsLnkbWOn0NuRmtQy+qKbtV1U1UcK02d6pAH4ixH5fSfMLhq1Slt59ugqvTc3B2YXVXBvuDqEhw8FjUq1JLDXHPH14/c1fHWET9GLhQG1qSRte5tdgNid+ZnPZ0TOqtVsLVpYmkyNpuKoANNylmFypIpkkWsdt9jvac7kWZbGm8ovHhXOTVU06hvUUX1Hm69z6jr8pt5vmvl8CWL9b8l/wBZRcsxJp1UqLzDDbuDsR8wTJyjepVF9yzi/wAzvOYLo3ycNvktmYD9VU/uP/hM+YSrtY85kxFPUrLe2pSL87XFpo1BYn3lUng9KCzlElI6lhVd6txyqWFttvLpk/mT9ZjGNHIPc9hxH6DeecP5nEQrnU2q/wAHQDcMQenaceH2hhxfDNLM/DRZi9JgL/da/wCTD+UhcZlFWmCWAsOZBB5y7YVan39PsCW+pIE0M9oXUqT8RH5EEyi2mOG0btPrLNyg3lFJSlUILWUAfeJJ37AWFz85jFLqTc/kPYfx5yxYjBBgouQo6CauONGhTJJVSwIBYgE97XmTa/B6SuXki5e/AikYdj3qm3yVB+8SlYColRCysrAki6kMNvUS8Vc2oYKjTp3LNpBCD4jq31N+EEn+V5s01Di1N/I8n4hr4TjKpeH/AH9TF4uwrXSuvThJ7WN1P1J/KbFSpUqUnWgP1tcuw3sEQWp6yel1UW9T6GVLMvF2Iq3AK01O2lQCSOxZv4WjDYyumEsjModzrr8ZFOkgVUUuBdRfVsPQDmZuPn3NZeCbyfwGNV8RUVrHelTJ9+Nzv8gB7yZxNYJwJwInCqrwgW9B6zW8K1qT0fIw1QIACWYi1dy3xOEIstzybiHIWkrl/h6jSprTBqPpFtdRy7ncniY8+cq1FU7IpQeC7TyhB5kjcyzENUphmFj+8DrNufFWwsJ9miCaik3krk03lCIiSOCIiAIiIAiIgCaWcYiqlMtRTW3bsOpsN29puxAKB/zPibm5U91Ki3sesq+Lwd2ZkAAJJ0DYC/Rb9J1jMMno1t3QX/GOFvqOfzlVz3w8tBfMWoSCwUKQL73PxD27SuXCyxCqVklFdsp2DwZJ1HhAPX0knhMxSnUBBuQeoNtxbny6yGx2aBUaq5sg5AdbcvcmRmGzq9ZaNQKpfZVRjVYVPNNMU30LbWSL7G1iN95lzOXKPpKtFpdOlGzmT/v2OpJjPMUvqIF7CmmzEnlqY7jvcWsAbkgbRWNx9NRsEZr71XAa3ohbcgdz/tCYHFG5p77rcb8x2PpK/m+YVUIta9g1yQAbEtUuSPhVR93fjHbdGTlwuyNmihW3Kbe39eTpPh1WbVUZiQbKN7+vy6SIreJ69KoyOlNtLEcip2O1jft6TQybN2o3fTdSF4b23bmLi4v169e8yZ+9Ov8A9RR5gAVKZ2YW2DW6joSPSWRe7s8vW1+hLZCXv9mWbKM+pV+EcD/gbr/dPX9/pIDxL4lFBalSoruoqBVVbbc16kWB2+crikg3GxG4I2IPpJnGZGcZhWV6gp+ZazldRLBg19NxcXE5Y4Rj+N8FFF9kpxx2ip477SnNxRoKvZnYt/8AhQP3yAznC4mrRGOxD31MFVTsQjXIKgbKLjl1veTY+zqvSqq1RqdTDqdTuhN9I3syMLi522vseclcbiUrMcPUphl5qDsLgfdI3BtexB6HkLXjB1rmHJ6qhZb3LHOOfL+Rj8DuFwSkg/HUt68R/r5SQr09RLBiWO9m3Jt2PXbpMFfLdFJaVI8KhVF+ul7vq2tdt97deU8eHsIyBabnkTYEgmwB7bAb8unLpeHN95+xa9BTJbXHtZ3e5uZRlr4iqtJOZ5t0VerH+uwnU8Vi6WESlQClrjQlMWJIAsSb8+fzJnPsFUajcUnZQbXAJGq3K5Ug/K9t5aMBpZL1KlXC35sFp0w5A/8AfKX+pB52vaaV0fO1YUuVk9Y7BYSliF8uhpZf1j1abNSWkP7QThJt90jcG295YcszOnXBanewNtxbpfaYcLlFHSNvMXmNR1Ib9Qg4L+oF5v0KCoNKKFA6AAD6CdSefYubr2Y24kZIiJMqEREAREQBERAEREAREQBIHxml6APaoD+TD+MnphxmGWojU25MLfyI9byM1mLRbRZ6dkZvwziGbYLUpVQLqSyqV1gkA6QQWGxJG99ue9rGBwuWuapLUra2/WEGoq6HpqWsx2b9ZfhC8xsdNp1TN/C1RbkDzF6MvxD3X+V5WxllbVpuP2Tq/ZmNSnBbcH022jUtWbhg6PF5nYED3M+YzCK29h3N0Lgeu3KXXI/C91JrAgEEKnUX+8ex9JF18NUwVdWO4BuGHJ16j0NuYkoU/hyzz9Z8TlC78pprHPyKnisQCAgOw3J5XPtNvAZcxAqAP6FQf3zo+c4BlJxOHJD83QbrVUczpIPEB1AuQLdra2JzyqFCh6CO1iDUvSuDv+ruSj7dVciXqCijx7Jyvt3TfL/4U6lkhc/9twCd2swAHU9hM3ifOGo008sWLOaa8JfSqKzMQo5nSlgOVyOgl3fPKICU3qLUdxY+Vxi52PLlueXOQed5IjhqVRAVJJ6ruQRqRhuDYnccrzDq8KcZPmK7NmlhsT+b6f8ABWvCudPjKR8wKKq6dSqdiHG11O4uBftv3BsxGVqKttgQbam2FulyFJA9u8nMlyUUjoo09ILXO+q+5Nl34Rcmw2Audpaq+Q0aigOvEB8Y4W+vX5yOlirLJOKxEvu1NlMUoPkhco8GKAXrVdereybJv1BNyfyktgvDOGpksKYYn8ViPmLWPzm9lmB8lPLDMwBNtVrgHpt63+s256ShHvB5y1Fu3buePqYaOFpr8KKvsoH7p5x2DSqhp1BdT09jcEfObESeCtNp5Rq5dgVooKakkAk77nc3m1ETiWBKTk8vsRETpwREQBERAEREAREQBERAEREAREQBMOKwyVFKVFDKeh/h2PrM0QD4BbaQODrr59TBPTBQcVPVZhYgMRY9ASbdht0k/POgXvYX5X6295xp+CcHFZ3LPHHt7kbjMlVkKpUq0yeRFR2A9lY7D0FpnyvAmlT0M5qb3u3T0HpN2I2rOR6ktmzx2fAoHKfYidICIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgH/9k='),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Text(
          'Bunda Hebat',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '@bundahebat123',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            'Menyebarkan positivitas dan saling mendukung. Di sini untuk mendengar dan membantu.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 24),
        _buildStatsSection(context),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildActions(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(context, '28', 'Postingan'),
          _buildStatColumn(context, '1.2K', 'Pengikut'),
          _buildStatColumn(context, '152', 'Koneksi'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const EditProfilePage(),
              ));
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            label: const Text('Edit Profil'),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ));
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _buildTextPostsList(List<Post> posts) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostCard(post: posts[index]);
      },
    );
  }

  Widget _buildUserPostsGrid(List<Post> posts) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PostDetailPage(posts: posts, initialIndex: index),
            ));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: post.assetPath != null
                ? Image.asset(post.assetPath!, fit: BoxFit.cover)
                : Image.network(post.imageUrl!, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  Widget _buildCreatePostButton() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CreatePostPage(),
          fullscreenDialog: true,
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Buat Postingan Baru',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.add_circle_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPostsTab() {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (isViewingOwnProfile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Text(
                  'Koleksi Pribadi',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: _isCollectionPrivate,
                  onChanged: (value) {
                    setState(() {
                      _isCollectionPrivate = value;
                    });
                  },
                ),
              ],
            ),
          ),
        if (isViewingOwnProfile || !_isCollectionPrivate) ...[
          const Divider(height: 1),
          TabBar(
            controller: _savedTabController,
            indicatorColor: theme.colorScheme.secondary,
            labelColor: theme.colorScheme.secondary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(icon: Icon(Icons.image_outlined)),
              Tab(icon: Icon(Icons.notes_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _savedTabController,
              children: [
                _buildUserPostsGrid(_savedImagePosts),
                _buildTextPostsList(_savedTextPosts),
              ],
            ),
          ),
        ] else
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 48),
                  SizedBox(height: 16),
                  Text('Koleksi pengguna ini bersifat pribadi.'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}